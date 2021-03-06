#Determine overlay of replicates with or without the use batch-effect correction methods such as Harmony
source("R:/RESRoberts/Bioinformatics/Analysis/Sanjana/scSeurat.R")
set.seed(108)
library("harmony")
#Cellecta and Zymo replicates merged with Harmony and without Harmony
#Cellecta
cellecta.cx.raw <- tenXLoadQC("R:/RESRoberts/Bioinformatics/scRNAOuts/S0015-cellecta/filtered_feature_bc_matrix/", 
                              spec = "mixHuman")
cellecta.cx.raw <- subset(cellecta.cx.raw, subset = nFeature_RNA >2500 & nCount_RNA <40000 & percent.mt <14)
cellecta.cx.raw$src <- "Cellecta_Cx"
cellecta.cx.raw$cond <- "Plate"
cellecta.cx.raw$rep <- "Rep1"

cellecta.lung.raw <- tenXLoadQC("R:/RESRoberts/Bioinformatics/scRNAOuts/S0023-cellecta-lung/filtered_feature_bc_matrix/", 
                                spec = "mixHuman")
cellecta.lung.raw <- subset(cellecta.lung.raw, subset = percent.mt <20 & percent.mt > 2)
cellecta.lung.raw$src <- "Cellecta_Lung"
cellecta.lung.raw$cond <- "Lung"
cellecta.lung.raw$rep <- "Rep1"

#Zymo
zymo.cx.raw <- tenXLoadQC(path10x = "R:/RESRoberts/Bioinformatics/scRNAOuts/S0016-zymo/filtered_feature_bc_matrix/", 
                          spec = "mixHuman")
zymo.cx.raw <- subset(zymo.cx.raw, subset = nFeature_RNA >3500 & nCount_RNA <50000 & percent.mt <15)
zymo.cx.raw$src <- "Zymo_Cx"
zymo.cx.raw$cond <- "Plate"
zymo.cx.raw$rep <- "Rep2"

zymo.tib.raw <- tenXLoadQC("R:/RESRoberts/Bioinformatics/scRNAOuts/S0018xS0028/filtered_feature_bc_matrix/",
                           spec = "mixHuman")
zymo.tib.raw <- subset(zymo.tib.raw, subset = nFeature_RNA >3000 & nCount_RNA <60000 & percent.mt <18)
zymo.tib.raw$src <- "Zymo_Tib"
zymo.tib.raw$cond <- "Bone"
zymo.tib.raw$rep <- "Rep2"

zymo.lung.raw<- tenXLoadQC(path10x = "R:/RESRoberts/Bioinformatics/scRNAOuts/S0024xS0029/filtered_feature_bc_matrix/", 
                           spec = "mixHuman")
zymo.lung.raw <- subset(zymo.lung.raw, subset = nFeature_RNA >1250 & nCount_RNA <60000 & percent.mt <25)
zymo.lung.raw$src <- "Zymo_Lung"
zymo.lung.raw$cond <- "Lung"
zymo.lung.raw$rep <- "Rep2"

#Subset to least number of cells across all conditions
#Subset all to #1900 cells

cellecta.cx.raw <- subset(cellecta.cx.raw, cells = sample(Cells(cellecta.cx.raw), 1900))
cellecta.lung.raw <- subset(cellecta.lung.raw, cells = sample(Cells(cellecta.lung.raw), 1900))
zymo.cx.raw <- subset(zymo.cx.raw, cells = sample(Cells(zymo.cx.raw), 1900))
zymo.lung.raw <- subset(zymo.lung.raw, cells = sample(Cells(zymo.lung.raw), 1900))

# Merge into a single Seurat object
Rep1_H <- merge(cellecta.cx.raw, y = c(cellecta.lung.raw, zymo.cx.raw, zymo.lung.raw),
              add.cell.ids = c("Cellecta_Cx", "Cellecta_Lung", "Zymo_Cx", "Zymo_Lung"),
              project = "Heterogeneity")

# Process and cluster
Rep1_H <- NormalizeData(Rep1_H) %>%
  FindVariableFeatures(selection.method = "vst") %>%
  ScaleData() %>%
  RunPCA(pc.genes = Rep1_H@var.genes, npcs = 20) %>%
  RunUMAP(reduction = "pca", dims = 1:20) %>%
  FindNeighbors(reduction = "pca", dims = 1:20) %>%
  FindClusters(resolution = 0.2) ##Note change in resolution

s.genes <- cc.genes$s.genes
g2m.genes <- cc.genes$g2m.genes
Rep1_H <- CellCycleScoring(object = Rep1_H, s.features = s.genes,
                                g2m.features = g2m.genes, set.ident = TRUE)
DimPlot(Rep1_H, reduction = "umap", pt.size = 1, label = F, split.by = "src") + 
  coord_fixed() + 
  ggtitle("Reps by Source") + 
  scale_color_npg(alpha = 0.7)

# Regress out the effects of cell cycle on these tumor cells
Rep1_H <- ScaleData(object = Rep1_H, vars.to.regress = c("S.Score", "G2M.Score"),
                  features = rownames(x = Rep1_H))

#without second Harmony
Rep1_H_v1 <- Rep1_H %>%
    RunPCA(pc.genes = Rep1_H_v1@var.genes, npcs = 20) %>%
  RunUMAP(reduction = "pca", dims = 1:20) %>%
  FindNeighbors(reduction = "pca", dims = 1:20) %>%
  FindClusters(resolution = 0.2) ##Note change in resolution

DimPlot(Rep1_H_v1, reduction = "umap", pt.size = 1, label = F, group.by = "cond") + 
  coord_fixed() + 
  ggtitle("Reps by Source") + 
  scale_color_npg(alpha = 0.7)

#With second Harmony
Rep1_H_v2 <- Rep1_H %>%
  RunPCA(pc.genes = Rep1_H_v2@var.genes, npcs = 20) %>%
  RunHarmony(group.by.vars = "src", plot_convergence = T) %>%
  RunUMAP(reduction = "harmony", dims = 1:20) %>%
  FindNeighbors(reduction = "harmony", dims = 1:20) %>%
  FindClusters(resolution = 0.2) ##Note change in resolution


DimPlot(Rep1_H_v2, reduction = "umap", pt.size = 1, label = F, split.by = "cond") + 
  coord_fixed() + 
  ggtitle("Reps by Source") + 
  scale_color_npg(alpha = 0.7)