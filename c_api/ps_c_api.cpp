/* C API implementation – instantiates C++ templates and converts types. */

#include "ps_c_api.h"
#include <cstdlib>
#include <vector>

/* PointSampler C++ headers */
#include "../PointSampler/include/point_sampler/point.hpp"
#include "../PointSampler/include/point_sampler/random.hpp"
#include "../PointSampler/include/point_sampler/halton.hpp"
#include "../PointSampler/include/point_sampler/hammersley.hpp"
#include "../PointSampler/include/point_sampler/poisson_disk_sampling.hpp"
#include "../PointSampler/include/point_sampler/range.hpp"
#include "../PointSampler/include/point_sampler/utils.hpp"
#include "../PointSampler/include/point_sampler/distance_rejection_filter.hpp"
#include "../PointSampler/include/point_sampler/dbscan_clustering.hpp"
#include "../PointSampler/include/point_sampler/kmeans_clustering.hpp"

/* ------------------------------------------------------------------ */
/*  Helpers                                                           */
/* ------------------------------------------------------------------ */

template<typename T, size_t N>
static void vec_to_flat(const std::vector<ps::Point<T, N>> &src, T **out)
{
  size_t total = src.size() * N;
  *out = (T*)std::malloc(total * sizeof(T));
  if (!*out) return;
  for (size_t i = 0; i < src.size(); ++i)
    for (size_t d = 0; d < N; ++d)
      (*out)[i * N + d] = src[i][d];
}

template<typename T, size_t N>
static std::vector<ps::Point<T, N>> flat_to_vec(const T *data, size_t count)
{
  std::vector<ps::Point<T, N>> pts(count);
  for (size_t i = 0; i < count; ++i)
    for (size_t d = 0; d < N; ++d)
      pts[i][d] = data[i * N + d];
  return pts;
}

template<typename T, size_t N>
static std::array<std::pair<T, T>, N> flat_to_ranges(const T *ranges)
{
  std::array<std::pair<T, T>, N> arr;
  for (size_t i = 0; i < N; ++i)
    arr[i] = {ranges[2*i], ranges[2*i+1]};
  return arr;
}

void ps_free(void *p) { std::free(p); }

/* ------------------------------------------------------------------ */
/*  Random                                                           */
/* ------------------------------------------------------------------ */

#define DEF_RANDOM(T, N, suffix)                                                \
  int ps_random_##suffix(size_t count, const T *ranges, T **out) {             \
    auto rr = flat_to_ranges<T, N>(ranges);                                    \
    auto pts = ps::random<T, N>(count, rr);                                    \
    vec_to_flat<T, N>(pts, out);                                               \
    return (int)pts.size();                                                    \
  }                                                                            \
  int ps_random_s_##suffix(size_t count, const T *ranges,                      \
                            uint32_t seed, T **out) {                          \
    auto rr = flat_to_ranges<T, N>(ranges);                                    \
    auto pts = ps::random<T, N>(count, rr, seed);                              \
    vec_to_flat<T, N>(pts, out);                                               \
    return (int)pts.size();                                                    \
  }

DEF_RANDOM(float,  2, f2)
DEF_RANDOM(double, 2, d2)

/* ------------------------------------------------------------------ */
/*  Halton                                                           */
/* ------------------------------------------------------------------ */

#define DEF_HALTON(T, N, suffix)                                                \
  int ps_halton_##suffix(size_t count, const T *ranges, T **out) {             \
    auto rr = flat_to_ranges<T, N>(ranges);                                    \
    auto pts = ps::halton<T, N>(count, rr);                                    \
    vec_to_flat<T, N>(pts, out);                                               \
    return (int)pts.size();                                                    \
  }                                                                            \
  int ps_halton_s_##suffix(size_t count, const T *ranges,                      \
                           uint32_t seed, T **out) {                            \
    auto rr = flat_to_ranges<T, N>(ranges);                                    \
    std::optional<unsigned int> opt_seed = seed;                               \
    auto pts = ps::halton<T, N>(count, rr, opt_seed);                          \
    vec_to_flat<T, N>(pts, out);                                               \
    return (int)pts.size();                                                    \
  }

DEF_HALTON(float,  2, f2)
DEF_HALTON(double, 2, d2)

/* ------------------------------------------------------------------ */
/*  Hammersley                                                       */
/* ------------------------------------------------------------------ */

#define DEF_HAMMERSLEY(T, N, suffix)                                            \
  int ps_hammersley_##suffix(size_t count, const T *ranges, T **out) {         \
    auto pts = ps::hammersley<T, N>(count, flat_to_ranges<T, N>(ranges));      \
    vec_to_flat<T, N>(pts, out);                                               \
    return (int)pts.size();                                                    \
  }

DEF_HAMMERSLEY(float,  2, f2)
DEF_HAMMERSLEY(double, 2, d2)

/* ------------------------------------------------------------------ */
/*  Poisson disk uniform                                             */
/* ------------------------------------------------------------------ */

#define DEF_POISSON(T, N, suffix)                                               \
  int ps_poisson_uniform_##suffix(size_t count, const T *ranges,               \
                                   T base_min_dist, T **out) {                 \
    auto rr = flat_to_ranges<T, N>(ranges);                                    \
    auto pts = ps::poisson_disk_sampling_uniform<T, N>(                        \
        count, rr, base_min_dist);                                              \
    vec_to_flat<T, N>(pts, out);                                               \
    return (int)pts.size();                                                    \
  }

DEF_POISSON(float,  2, f2)
DEF_POISSON(double, 2, d2)

/* ------------------------------------------------------------------ */
/*  Range filter                                                     */
/* ------------------------------------------------------------------ */

#define DEF_FILTER_RANGE(T, N, suffix)                                          \
  int ps_filter_range_##suffix(const T *points, size_t n,                      \
                                const T *ranges, T **out) {                    \
    auto pts = flat_to_vec<T, N>(points, n);                                   \
    auto rr = flat_to_ranges<T, N>(ranges);                                    \
    auto filtered = ps::filter_points_in_range<T, N>(pts, rr);                 \
    vec_to_flat<T, N>(filtered, out);                                          \
    return (int)filtered.size();                                               \
  }

DEF_FILTER_RANGE(float,  2, f2)
DEF_FILTER_RANGE(double, 2, d2)

/* ------------------------------------------------------------------ */
/*  Distance rejection filter                                        */
/* ------------------------------------------------------------------ */

int ps_dist_reject_f2(const float *points, size_t n,
                       float radius, float **out)
{
  auto pts = flat_to_vec<float, 2>(points, n);
  auto filtered = ps::distance_rejection_filter<float, 2>(pts, radius);
  vec_to_flat<float, 2>(filtered, out);
  return (int)filtered.size();
}

/* ------------------------------------------------------------------ */
/*  DBSCAN clustering — returns labels array, nClusters computed in Nim */
/* ------------------------------------------------------------------ */

#define DEF_DBSCAN(T, N, suffix)                                                \
  int ps_dbscan_##suffix(const T *points, size_t n,                            \
                          T eps, size_t min_pts,                               \
                          int **out_labels, int *out_n_clusters) {              \
    auto pts = flat_to_vec<T, N>(points, n);                                   \
    auto labels = ps::dbscan_clustering<T, N>(pts, eps, min_pts);              \
    *out_labels = (int*)std::malloc(n * sizeof(int));                          \
    if (!*out_labels) return -1;                                               \
    for (size_t i = 0; i < n; ++i) (*out_labels)[i] = labels[i];              \
    *out_n_clusters = 0;                                                       \
    for (size_t i = 0; i < n; ++i)                                             \
      if (labels[i] > *out_n_clusters) *out_n_clusters = labels[i];            \
    (*out_n_clusters)++;                                                       \
    return (int)n;                                                             \
  }

DEF_DBSCAN(float,  2, f2)
DEF_DBSCAN(double, 2, d2)

/* ------------------------------------------------------------------ */
/*  K-means clustering                                               */
/* ------------------------------------------------------------------ */

#define DEF_KMEANS(T, N, suffix)                                                \
  int ps_kmeans_##suffix(const T *points, size_t n,                             \
                          int k, int max_iter,                                  \
                          T **out_centroids, int **out_labels) {                \
    auto pts = flat_to_vec<T, N>(points, n);                                    \
    auto result = ps::kmeans_clustering<T, N>(                                  \
        pts, (size_t)k, true, (size_t)max_iter);                                \
    auto &centroids = result.first;                                             \
    auto &labels = result.second;                                               \
    vec_to_flat<T, N>(centroids, out_centroids);                                \
    *out_labels = (int*)std::malloc(n * sizeof(int));                          \
    if (!*out_labels) return -1;                                               \
    for (size_t i = 0; i < n; ++i) (*out_labels)[i] = (int)labels[i];         \
    return (int)centroids.size();                                              \
  }

DEF_KMEANS(float,  2, f2)
DEF_KMEANS(double, 2, d2)
