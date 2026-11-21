"""K-Means model selection and stability diagnostics (exploratory)."""
import numpy as np
import pandas as pd
from sklearn.cluster import AgglomerativeClustering, KMeans
from sklearn.metrics import (adjusted_rand_score, calinski_harabasz_score,
                             davies_bouldin_score, silhouette_score)
from sklearn.mixture import GaussianMixture
from sklearn.preprocessing import StandardScaler
from sklearn.tree import DecisionTreeClassifier

from .config import RANDOM_STATE

ORIGINAL_FEATURES = ["recency_days", "frequency", "monetary_value_capped", "email_open_rate", "churn_risk_score"]
REVISED_FEATURES = ["recency_days", "frequency", "log_monetary"]


def scale(df, features):
    return StandardScaler().fit_transform(df[features])


def fit_kmeans(X, k, seed=RANDOM_STATE, n_init=20):
    return KMeans(n_clusters=k, random_state=seed, n_init=n_init, max_iter=500).fit(X)


def bootstrap_ari(X, labels, k, n_boot=50, frac=0.8, seed=0):
    """Refit on random 80% subsamples and compare with the full-data labels on the same customers."""
    rng = np.random.default_rng(seed)
    scores = []
    for b in range(n_boot):
        idx = rng.choice(len(X), int(frac * len(X)), replace=False)
        sub = KMeans(n_clusters=k, random_state=b, n_init=10).fit_predict(X[idx])
        scores.append(adjusted_rand_score(labels[idx], sub))
    return np.array(scores)


def shuffle_ari(X, labels, k, n_shuffles=20, seed=0):
    """Refit after permuting row order only (same random_state); compare assignments."""
    rng = np.random.default_rng(seed)
    scores = []
    for _ in range(n_shuffles):
        perm = rng.permutation(len(X))
        lab = fit_kmeans(X[perm], k).labels_
        back = np.empty_like(lab)
        back[perm] = lab
        scores.append(adjusted_rand_score(labels, back))
    return np.array(scores)


def null_silhouette(X, k, n=10):
    """Silhouette after shuffling each column independently: same marginals, no joint structure."""
    vals = []
    for s in range(n):
        Xs = X.copy()
        for j in range(Xs.shape[1]):
            Xs[:, j] = np.random.default_rng(s * 100 + j).permutation(Xs[:, j])
        vals.append(silhouette_score(Xs, KMeans(n_clusters=k, random_state=s, n_init=10).fit_predict(Xs)))
    return float(np.mean(vals))


def model_selection(X, k_range=range(2, 9), n_boot=50):
    rows = []
    for k in k_range:
        km = fit_kmeans(X, k)
        lab = km.labels_
        boot = bootstrap_ari(X, lab, k, n_boot=n_boot)
        shuf = shuffle_ari(X, lab, k)
        ward = AgglomerativeClustering(n_clusters=k, linkage="ward").fit_predict(X)
        gmm = GaussianMixture(n_components=k, random_state=RANDOM_STATE, n_init=5).fit(X)
        sizes = np.bincount(lab)
        rows.append({
            "k": k,
            "inertia": km.inertia_,
            "silhouette": silhouette_score(X, lab),
            "null_silhouette": null_silhouette(X, k),
            "davies_bouldin": davies_bouldin_score(X, lab),
            "calinski_harabasz": calinski_harabasz_score(X, lab),
            "bootstrap_ari_mean": boot.mean(),
            "bootstrap_ari_min": boot.min(),
            "row_shuffle_ari_min": shuf.min(),
            "ward_agreement_ari": adjusted_rand_score(lab, ward),
            "gmm_bic": gmm.bic(X),
            "smallest_cluster": int(sizes.min()),
            "largest_cluster": int(sizes.max()),
        })
    return pd.DataFrame(rows).set_index("k")


def rule_reproduction(df, features, labels, depth=2):
    """Accuracy of a shallow decision tree at reproducing cluster labels from raw features."""
    tree = DecisionTreeClassifier(max_depth=depth, random_state=RANDOM_STATE).fit(df[features], labels)
    return tree, float(tree.score(df[features], labels))


def eta_squared(df, labels, features):
    """Share of each feature's variance explained by cluster membership."""
    out = {}
    for f in features:
        x = df[f]
        ssb = sum(len(x[labels == c]) * (x[labels == c].mean() - x.mean()) ** 2 for c in np.unique(labels))
        out[f] = ssb / ((x - x.mean()) ** 2).sum()
    return pd.Series(out)


def relabel_by_centroid(df, labels, key="recency_days"):
    """Renumber clusters by ascending median of `key` so labels are stable across runs."""
    order = pd.Series(df[key].values).groupby(labels).median().sort_values().index
    mapping = {old: new for new, old in enumerate(order)}
    return np.array([mapping[l] for l in labels])
