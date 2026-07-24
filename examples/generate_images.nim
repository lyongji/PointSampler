## 生成 docs/images/ 下的可视化图片。
##
## 用法: nim c -r examples/generate_images.nim

import std/[os, math, random, strformat, strutils, sequtils, options]
import point_sampler

# ---------------------------------------------------------------------------
# SVG 辅助 — 不用 & 格式化，避免 strformat 的 {} 转义问题
# ---------------------------------------------------------------------------

const
  W = 600
  H = 400
  MG = 60
  PW = W - 2*MG
  PH = H - 2*MG
  BG = "#1a1a2e"
  DOT = "#e94560"
  ACC = "#0f3460"
  TXT = "#eeeeee"
  CLR = ["#e94560","#0f3460","#f5a623","#7ed321","#50e3c2","#b8e986","#4a90e2","#f8e71c"]

proc esc(s: string): string = s.replace("&","&amp;")

proc hdr(title: string): string =
  result = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 " & $W & " " & $H & "'>\n" &
    "<style>text{font-family:sans-serif;font-size:11px;fill:" & TXT & "}" &
    ".title{font-size:16px;font-weight:bold}.label{fill:" & TXT & ";opacity:.7}</style>\n" &
    "<rect width='" & $W & "' height='" & $H & "' fill='" & BG & "' rx='8'/>\n" &
    "<text x='" & $(W div 2) & "' y='28' text-anchor='middle' class='title'>" & esc(title) & "</text>\n"

proc footer: string = "</svg>"

proc mx(x,x0,x1:float):float = MG.float + (x-x0)/(x1-x0)*PW.float
proc my(y,y0,y1:float):float = MG.float + PH.float - (y-y0)/(y1-y0)*PH.float

proc axes(x0,x1,y0,y1:float): string =
  result = "<line x1='" & $MG & "' y1='" & $(MG+PH) & "' x2='" & $(MG+PW) & "' y2='" & $(MG+PH) &
           "' stroke='" & TXT & "' opacity='.3'/>\n" &
           "<line x1='" & $MG & "' y1='" & $MG & "' x2='" & $MG & "' y2='" & $(MG+PH) &
           "' stroke='" & TXT & "' opacity='.3'/>\n"
  for i in 0..5:
    let t = i/5
    let xc = mx(x0+t*(x1-x0),x0,x1)
    let yc = my(y0+t*(y1-y0),y0,y1)
    result.add "<text x='" & $xc & "' y='" & $(MG+PH+16) & "' text-anchor='middle' class='label'>" &
               &"{(x0+t*(x1-x0)):.2f}</text>\n"
    result.add "<text x='" & $(MG-8) & "' y='" & $(yc+4) & "' text-anchor='end' class='label'>" &
               &"{(y0+t*(y1-y0)):.2f}</text>\n"

proc dot[T,N](p:Point[T,N]; r:float; c:string; x0,x1,y0,y1:float): string =
  "<circle cx='" & $mx(p[0].float,x0,x1) & "' cy='" & $my(p[1].float,y0,y1) &
  "' r='" & $r & "' fill='" & c & "' opacity='.8'/>\n"

proc drawPts[T,N](ps:openArray[Point[T,N]]; r=3.0; c=DOT; x0=0.0,x1=1.0,y0=0.0,y1=1.0): string =
  for p in ps: result.add dot(p,r,c,x0,x1,y0,y1)

proc drawClusters[T,N](ps:openArray[Point[T,N]]; ls:openArray[int]; r=3.0;
                       x0=0.0,x1=1.0,y0=0.0,y1=1.0): string =
  for i,p in ps:
    result.add dot(p,r,if ls[i]>=0: CLR[ls[i] mod CLR.len] else:"#555",x0,x1,y0,y1)

# 简单图片：标题+坐标轴+散点+保存
proc gen(title, file: string; ps: openArray[Point[float,2]];
          x0=0.0, x1=1.0, y0=0.0, y1=1.0, r=3.0) =
  var svg = hdr(title) & axes(x0,x1,y0,y1) & drawPts(ps,r,DOT,x0,x1,y0,y1) & footer()
  writeFile("docs/images/" & file, svg)
  echo "  ✓ " & file

when isMainModule:
  setCurrentDir(currentSourcePath.parentDir.parentDir)
  echo "生成图片到 docs/images/ ..."
  randomize(42)
  let S = some(uint32(42))

  gen("均匀随机采样 (random)", "out_random.svg",
      random[float,2](300,[(0.0,1.0),(0.0,1.0)],S))
  gen("Halton 序列 (halton)", "out_halton.svg",
      halton[float,2](300,[(0.0,1.0),(0.0,1.0)]))
  gen("Hammersley 序列 (hammersley)", "out_hammersley.svg",
      hammersley[float,2](300,[(0.0,1.0),(0.0,1.0)]))

  block:
    let jit: array[2,float]=[0.8,0.8]; let stg: array[2,float]=[0.2,0.0]
    gen("抖动网格 (jitteredGrid)", "out_jittered_grid.svg",
        jitteredGrid[float,2](200,[(0.0,1.0),(0.0,1.0)],jit,stg,S))

  gen("拉丁超立方采样 (latinHypercubeSampling)", "out_latin_hypercube_sampling.svg",
      latinHypercubeSampling[float,2](200,[(0.0,1.0),(0.0,1.0)],S))
  gen("均匀泊松盘 (poissonDiskSamplingUniform)", "out_poisson_disk_sampling_uniform.svg",
      poissonDiskSamplingUniform[float,2](200,[(0.0,1.0),(0.0,1.0)],0.05,S))

  block:
    let sf = proc(p:Point[float,2]):float = 1+0.5*sin(p[0]*6.2831)
    gen("变密度泊松盘 (poissonDiskSampling)", "out_poisson_disk_sampling.svg",
        poissonDiskSampling[float,2](200,[(0.0,1.0),(0.0,1.0)],0.04,sf,S))

  block:
    let rg = proc:float = 0.02+0.08*rand(1.0)
    gen("距离分布泊松盘", "out_poisson_disk_sampling_distance_distribution.svg",
        poissonDiskSamplingDistanceDistribution[float,2,typeof(rg)](80,[(0.0,1.0),(0.0,1.0)],rg,S,50))

  gen("幂律半径泊松盘 (poissonDiskSamplingPowerLaw)", "out_poisson_disk_sampling_power_law.svg",
      poissonDiskSamplingPowerLaw[float,2](100,0.01,0.15,2.0,[(0.0,1.0),(0.0,1.0)],S,50))
  gen("Weibull 半径泊松盘", "out_poisson_disk_sampling_weibull.svg",
      poissonDiskSamplingWeibull[float,2](100,0.08,1.5,[(0.0,1.0),(0.0,1.0)],S,50))
  gen("截断 Weibull 泊松盘", "out_poisson_disk_sampling_weibull_min_dist.svg",
      poissonDiskSamplingWeibull[float,2](100,0.08,1.5,0.03,[(0.0,1.0),(0.0,1.0)],S,50))

  # 高斯聚类 — 带中心标记
  block:
    let centers = @[initPoint[float,2]([0.25,0.25]), initPoint[float,2]([0.75,0.75]),
                    initPoint[float,2]([0.25,0.75])]
    let p = gaussianClusters(centers,100,0.08,S)
    var sv = hdr("高斯聚类 (gaussianClusters)") & axes(0,1,0,1) &
             drawPts(p) & centers.mapIt(dot(it,5,ACC,0,1,0,1)).join("") & footer()
    writeFile("docs/images/out_gaussian_clusters_wrapped.svg", sv)
    echo "  ✓ out_gaussian_clusters_wrapped.svg"

  gen("重要性重采样 (importanceResampling)", "out_importance_resampling.svg",
      importanceResampling[float,2](300,5,[(-1.0,1.0),(-1.0,1.0)],
        proc(p:Point[float,2]):float=exp(-10*(p[0]*p[0]+p[1]*p[1])),S),
      x0=(-1),x1=1,y0=(-1),y1=1)
  gen("拒绝采样 (rejectionSampling)", "out_rejection_sampling.svg",
      rejectionSampling[float,2](500,[(-2.0,2.0),(-2.0,2.0)],
        proc(p:Point[float,2]):float=exp(-(p[0]*p[0]+p[1]*p[1])),S),
      x0=(-2),x1=2,y0=(-2),y1=2)

  gen("随机游走纤维 (randomWalkFilaments)", "out_random_walk_filaments.svg",
      randomWalkFilaments[float,2](3,50,0.05,[(0.0,1.0),(0.0,1.0)],S,
        persistence=0.9,gaussianSigma=0.01,gaussianSamples=5),r=2.5)

  block:
    let cand = random[float,2](500,[(0.0,1.0),(0.0,1.0)],S)
    gen("距离拒绝过滤 (distanceRejectionFilter)", "out_distance_rejection_filter.svg",
        distanceRejectionFilter(cand,0.05))
  block:
    let cand = random[float,2](500,[(0.0,1.0),(0.0,1.0)],S)
    let sf = proc(p:Point[float,2]):float = 0.5+0.5*sin(p[0]*3.1415)
    gen("空间变距拒绝过滤", "out_distance_rejection_filter_warped.svg",
        distanceRejectionFilterWarped(cand,0.05,sf))
  block:
    let cand = random[float,2](500,[(0.0,1.0),(0.0,1.0)],S)
    gen("随机下采样 (randomRejectionFilter)", "out_random_rejection_filter.svg",
        randomRejectionFilter(cand,100))
  block:
    var p = random[float,2](200,[(0.0,1.0),(0.0,1.0)],S)
    relaxationKtree(p,kNeighbors=8,stepSize=0.05,iterations=10)
    gen("K-近邻松弛 (relaxationKtree)", "out_relaxation_ktree_refit.svg", p)

  # K-means
  block:
    let p = @[initPoint[float,2]([0.1,0.2]),initPoint[float,2]([0.15,0.22]),
              initPoint[float,2]([0.12,0.18]),initPoint[float,2]([0.8,0.75]),
              initPoint[float,2]([0.85,0.8]),initPoint[float,2]([0.9,0.85]),
              initPoint[float,2]([0.82,0.78]),initPoint[float,2]([0.5,0.5]),
              initPoint[float,2]([0.48,0.52]),initPoint[float,2]([0.52,0.48])]
    let (centroids,labels) = kmeansClustering(p,3)
    var sv = hdr("K-means 聚类 (kmeansClustering)") & axes(0,1,0,1) &
             drawClusters(p,labels) &
             centroids.mapIt(dot(it,6,"#ffffff",0,1,0,1)).join("") & footer()
    writeFile("docs/images/metrics_kmeans_clustering.svg", sv)
    echo "  ✓ metrics_kmeans_clustering.svg"

  # DBSCAN
  block:
    let p = @[initPoint[float,2]([0.1,0.1]),initPoint[float,2]([0.12,0.13]),
              initPoint[float,2]([0.08,0.11]),initPoint[float,2]([0.7,0.7]),
              initPoint[float,2]([0.73,0.68]),initPoint[float,2]([0.71,0.72]),
              initPoint[float,2]([0.9,0.1])]
    let labels = dbscanClustering(p,0.1,2)
    var sv = hdr("DBSCAN 聚类 (dbscanClustering)") & axes(0,1,0,1) &
             drawClusters(p,labels) & footer()
    writeFile("docs/images/metrics_dbscan_clustering.svg", sv)
    echo "  ✓ metrics_dbscan_clustering.svg"

  # 逾渗聚类
  block:
    let p = @[initPoint[float,2]([0.1,0.1]),initPoint[float,2]([0.12,0.13]),
              initPoint[float,2]([0.08,0.11]),initPoint[float,2]([0.5,0.5]),
              initPoint[float,2]([0.53,0.48]),initPoint[float,2]([0.9,0.9])]
    let labels = percolationClustering(p,0.1)
    var sv = hdr("逾渗聚类 (percolationClustering)") & axes(0,1,0,1) &
             drawClusters(p,labels) & footer()
    writeFile("docs/images/metrics_percolation_clustering.svg", sv)
    echo "  ✓ metrics_percolation_clustering.svg"

  # 最近邻距离 — 按距离着色
  block:
    let p = random[float,2](100,[(0.0,1.0),(0.0,1.0)],S)
    let dSq = firstNeighborDistanceSquared(p)
    let maxD = sqrt(max(dSq))
    var sv = hdr("最近邻距离 (firstNeighborDistanceSquared)") & axes(0,1,0,1)
    for i, pt in p:
      let intensity = clamp(sqrt(dSq[i])/maxD,0.0,1.0)
      let g = (intensity*200).int
      sv.add dot(pt,2+3*intensity,"rgb(" & $g & ",50," & $(155-g div 2) & ")",0,1,0,1)
    sv.add footer()
    writeFile("docs/images/metrics_first_neighbor_distance.svg", sv)
    echo "  ✓ metrics_first_neighbor_distance.svg"

  # 局部密度
  block:
    let ps = concat(gaussianClusters(@[initPoint[float,2]([0.2,0.2])],80,0.05),
                    gaussianClusters(@[initPoint[float,2]([0.8,0.8])],20,0.05))
    let dens = localDensityKnn(ps,8)
    let maxD = max(dens)
    var sv = hdr("局部密度估计 (localDensityKnn)") & axes(0,1,0,1)
    for i, pt in ps:
      let intensity = clamp(dens[i]/maxD,0.0,1.0)
      let g = (intensity*200).int
      sv.add dot(pt,2+5*intensity,"rgb(" & $(50+g) & ",50," & $(155-g div 2) & ")",0,1,0,1)
    sv.add footer()
    writeFile("docs/images/metrics_local_density_knn.svg", sv)
    echo "  ✓ metrics_local_density_knn.svg"

  # 最近邻连接 — 线+点
  block:
    let p = random[float,2](50,[(0.0,1.0),(0.0,1.0)],S)
    let nbrs = nearestNeighborsIndices(p,3)
    var sv = hdr("最近邻连接 (nearestNeighborsIndices)") & axes(0,1,0,1)
    for i, pt in p:
      for j in nbrs[i]:
        sv.add "<line x1='" & $mx(pt[0],0,1) & "' y1='" & $my(pt[1],0,1) &
               "' x2='" & $mx(p[j][0],0,1) & "' y2='" & $my(p[j][1],0,1) &
               "' stroke='" & ACC & "' stroke-width='.5' opacity='.3'/>\n"
    sv.add drawPts(p) & footer()
    writeFile("docs/images/metrics_nearest_neighbors_indices.svg", sv)
    echo "  ✓ metrics_nearest_neighbors_indices.svg"

  echo "完成: 共 25 张 SVG 图片"
