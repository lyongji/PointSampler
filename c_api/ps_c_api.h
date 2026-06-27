/* C API for PointSampler (C++ → C wrapper).
 *
 * Each template instantiation (float/double × 2D) gets its own
 * extern "C" function. Points are passed as flat interleaved arrays
 * (x0,y0, x1,y1, ...) to avoid C++ type dependencies.
 *
 * Memory: output arrays are malloc'd by the callee; caller must free()
 * them via ps_free().
 *
 * ponytail: only 2D variants wired to Nim. Add 3D when a caller needs it.
 */

#ifndef PS_C_API_H
#define PS_C_API_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ---- Memory ---- */
void ps_free(void *p);

/* ---- Random ---- */
int ps_random_f2(size_t count, const float *ranges, float **out);
int ps_random_d2(size_t count, const double *ranges, double **out);
int ps_random_s_f2(size_t count, const float *ranges, uint32_t seed, float **out);
int ps_random_s_d2(size_t count, const double *ranges, uint32_t seed, double **out);

/* ---- Halton ---- */
int ps_halton_f2(size_t count, const float *ranges, float **out);
int ps_halton_d2(size_t count, const double *ranges, double **out);
int ps_halton_s_f2(size_t count, const float *ranges, uint32_t seed, float **out);
int ps_halton_s_d2(size_t count, const double *ranges, uint32_t seed, double **out);

/* ---- Hammersley ---- */
int ps_hammersley_f2(size_t count, const float *ranges, float **out);
int ps_hammersley_d2(size_t count, const double *ranges, double **out);

/* ---- Poisson disk uniform ---- */
int ps_poisson_uniform_f2(size_t count, const float *ranges,
                          float base_min_dist, float **out);
int ps_poisson_uniform_d2(size_t count, const double *ranges,
                          double base_min_dist, double **out);

/* ---- Range filter ---- */
int ps_filter_range_f2(const float *points, size_t n,
                       const float *ranges, float **out);
int ps_filter_range_d2(const double *points, size_t n,
                       const double *ranges, double **out);

/* ---- Distance rejection filter ---- */
int ps_dist_reject_f2(const float *points, size_t n,
                      float radius, float **out);

/* ---- DBSCAN clustering ---- */
int ps_dbscan_f2(const float *points, size_t n,
                 float eps, size_t min_pts,
                 int **out_labels, int *out_n_clusters);
int ps_dbscan_d2(const double *points, size_t n,
                 double eps, size_t min_pts,
                 int **out_labels, int *out_n_clusters);

/* ---- K-means clustering ---- */
int ps_kmeans_f2(const float *points, size_t n,
                 int k, int max_iter,
                 float **out_centroids, int **out_labels);
int ps_kmeans_d2(const double *points, size_t n,
                 int k, int max_iter,
                 double **out_centroids, int **out_labels);

#ifdef __cplusplus
}
#endif

#endif /* PS_C_API_H */
