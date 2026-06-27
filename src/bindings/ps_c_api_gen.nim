
{.warning[UnusedImport]: off.}
{.hint[XDeclaredButNotUsed]: off.}
from std / macros import hint, warning, newLit, getSize

from std / os import parentDir

when not declared(ownSizeOf):
  macro ownSizeof(x: typed): untyped =
    newLit(x.getSize)

when not declared(ps_free):
  proc ps_free*(p: pointer): void {.cdecl, importc: "ps_free".}
else:
  static :
    hint("Declaration of " & "ps_free" & " already exists, not redeclaring")
when not declared(ps_random_f2):
  proc ps_random_f2*(count: csize_t; ranges: ptr cfloat; out_arg: ptr ptr cfloat): cint {.
      cdecl, importc: "ps_random_f2".}
else:
  static :
    hint("Declaration of " & "ps_random_f2" & " already exists, not redeclaring")
when not declared(ps_random_d2):
  proc ps_random_d2*(count: csize_t; ranges: ptr cdouble;
                     out_arg: ptr ptr cdouble): cint {.cdecl,
      importc: "ps_random_d2".}
else:
  static :
    hint("Declaration of " & "ps_random_d2" & " already exists, not redeclaring")
when not declared(ps_random_s_f2):
  proc ps_random_s_f2*(count: csize_t; ranges: ptr cfloat; seed: uint32;
                       out_arg: ptr ptr cfloat): cint {.cdecl,
      importc: "ps_random_s_f2".}
else:
  static :
    hint("Declaration of " & "ps_random_s_f2" &
        " already exists, not redeclaring")
when not declared(ps_random_s_d2):
  proc ps_random_s_d2*(count: csize_t; ranges: ptr cdouble; seed: uint32;
                       out_arg: ptr ptr cdouble): cint {.cdecl,
      importc: "ps_random_s_d2".}
else:
  static :
    hint("Declaration of " & "ps_random_s_d2" &
        " already exists, not redeclaring")
when not declared(ps_halton_f2):
  proc ps_halton_f2*(count: csize_t; ranges: ptr cfloat; out_arg: ptr ptr cfloat): cint {.
      cdecl, importc: "ps_halton_f2".}
else:
  static :
    hint("Declaration of " & "ps_halton_f2" & " already exists, not redeclaring")
when not declared(ps_halton_d2):
  proc ps_halton_d2*(count: csize_t; ranges: ptr cdouble;
                     out_arg: ptr ptr cdouble): cint {.cdecl,
      importc: "ps_halton_d2".}
else:
  static :
    hint("Declaration of " & "ps_halton_d2" & " already exists, not redeclaring")
when not declared(ps_halton_s_f2):
  proc ps_halton_s_f2*(count: csize_t; ranges: ptr cfloat; seed: uint32;
                       out_arg: ptr ptr cfloat): cint {.cdecl,
      importc: "ps_halton_s_f2".}
else:
  static :
    hint("Declaration of " & "ps_halton_s_f2" &
        " already exists, not redeclaring")
when not declared(ps_halton_s_d2):
  proc ps_halton_s_d2*(count: csize_t; ranges: ptr cdouble; seed: uint32;
                       out_arg: ptr ptr cdouble): cint {.cdecl,
      importc: "ps_halton_s_d2".}
else:
  static :
    hint("Declaration of " & "ps_halton_s_d2" &
        " already exists, not redeclaring")
when not declared(ps_hammersley_f2):
  proc ps_hammersley_f2*(count: csize_t; ranges: ptr cfloat;
                         out_arg: ptr ptr cfloat): cint {.cdecl,
      importc: "ps_hammersley_f2".}
else:
  static :
    hint("Declaration of " & "ps_hammersley_f2" &
        " already exists, not redeclaring")
when not declared(ps_hammersley_d2):
  proc ps_hammersley_d2*(count: csize_t; ranges: ptr cdouble;
                         out_arg: ptr ptr cdouble): cint {.cdecl,
      importc: "ps_hammersley_d2".}
else:
  static :
    hint("Declaration of " & "ps_hammersley_d2" &
        " already exists, not redeclaring")
when not declared(ps_poisson_uniform_f2):
  proc ps_poisson_uniform_f2*(count: csize_t; ranges: ptr cfloat;
                              base_min_dist: cfloat; out_arg: ptr ptr cfloat): cint {.
      cdecl, importc: "ps_poisson_uniform_f2".}
else:
  static :
    hint("Declaration of " & "ps_poisson_uniform_f2" &
        " already exists, not redeclaring")
when not declared(ps_poisson_uniform_d2):
  proc ps_poisson_uniform_d2*(count: csize_t; ranges: ptr cdouble;
                              base_min_dist: cdouble; out_arg: ptr ptr cdouble): cint {.
      cdecl, importc: "ps_poisson_uniform_d2".}
else:
  static :
    hint("Declaration of " & "ps_poisson_uniform_d2" &
        " already exists, not redeclaring")
when not declared(ps_filter_range_f2):
  proc ps_filter_range_f2*(points: ptr cfloat; n: csize_t; ranges: ptr cfloat;
                           out_arg: ptr ptr cfloat): cint {.cdecl,
      importc: "ps_filter_range_f2".}
else:
  static :
    hint("Declaration of " & "ps_filter_range_f2" &
        " already exists, not redeclaring")
when not declared(ps_filter_range_d2):
  proc ps_filter_range_d2*(points: ptr cdouble; n: csize_t; ranges: ptr cdouble;
                           out_arg: ptr ptr cdouble): cint {.cdecl,
      importc: "ps_filter_range_d2".}
else:
  static :
    hint("Declaration of " & "ps_filter_range_d2" &
        " already exists, not redeclaring")
when not declared(ps_dist_reject_f2):
  proc ps_dist_reject_f2*(points: ptr cfloat; n: csize_t; radius: cfloat;
                          out_arg: ptr ptr cfloat): cint {.cdecl,
      importc: "ps_dist_reject_f2".}
else:
  static :
    hint("Declaration of " & "ps_dist_reject_f2" &
        " already exists, not redeclaring")
when not declared(ps_dbscan_f2):
  proc ps_dbscan_f2*(points: ptr cfloat; n: csize_t; eps: cfloat;
                     min_pts: csize_t; out_labels: ptr ptr cint;
                     out_n_clusters: ptr cint): cint {.cdecl,
      importc: "ps_dbscan_f2".}
else:
  static :
    hint("Declaration of " & "ps_dbscan_f2" & " already exists, not redeclaring")
when not declared(ps_dbscan_d2):
  proc ps_dbscan_d2*(points: ptr cdouble; n: csize_t; eps: cdouble;
                     min_pts: csize_t; out_labels: ptr ptr cint;
                     out_n_clusters: ptr cint): cint {.cdecl,
      importc: "ps_dbscan_d2".}
else:
  static :
    hint("Declaration of " & "ps_dbscan_d2" & " already exists, not redeclaring")
when not declared(ps_kmeans_f2):
  proc ps_kmeans_f2*(points: ptr cfloat; n: csize_t; k: cint; max_iter: cint;
                     out_centroids: ptr ptr cfloat; out_labels: ptr ptr cint): cint {.
      cdecl, importc: "ps_kmeans_f2".}
else:
  static :
    hint("Declaration of " & "ps_kmeans_f2" & " already exists, not redeclaring")
when not declared(ps_kmeans_d2):
  proc ps_kmeans_d2*(points: ptr cdouble; n: csize_t; k: cint; max_iter: cint;
                     out_centroids: ptr ptr cdouble; out_labels: ptr ptr cint): cint {.
      cdecl, importc: "ps_kmeans_d2".}
else:
  static :
    hint("Declaration of " & "ps_kmeans_d2" & " already exists, not redeclaring")