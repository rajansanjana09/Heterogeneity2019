source("R:/RESRoberts/Bioinformatics/Analysis/Sanjana/scSeurat.R")

# Create Seurat objects and perform initial QC.  Label original source.
cx.raw <- tenXLoadQC("R:/RESRoberts/Bioinformatics/scRNAOuts/S0016-zymo/filtered_feature_bc_matrix/", spec = "mixHuman")
cx.raw <- subset(cx.raw, subset = nFeature_RNA >3500 & nCount_RNA <50000 & percent.mt <15)
cx.raw$src <- "Culture"

tib.raw <- tenXLoadQC("R:/RESRoberts/Bioinformatics/scRNAOuts/S0018xS0028/filtered_feature_bc_matrix/", spec = "mixHuman")
tib.raw <- subset(tib.raw, subset = nFeature_RNA >3000 & nCount_RNA <60000 & percent.mt <18)
tib.raw$src <- "Tibia"

lung.raw <- tenXLoadQC("R:/RESRoberts/Bioinformatics/scRNAOuts/S0024xS0029/filtered_feature_bc_matrix/", spec = "mixHuman")
lung.raw <- subset(lung.raw, subset = nFeature_RNA >1250 & nCount_RNA <60000 & percent.mt <25)
lung.raw$src <- "Lung"

# Add lineage tracing tags to the Seurat objects
cx.raw <- processLTBC(cx.raw,
                      lt.loc = "R:/RESRoberts/Bioinformatics/scRNAOuts/S0016-zymo/lt.fq",
                      cid.loc = "R:/RESRoberts/Bioinformatics/scRNAOuts/S0016-zymo/cid.fq",
                      histogram = T,
                      title = "Culture, Top 40 Clones",
                      ymax = 1.75,
                      col.fill = "#E64B35FF",
                      relative = T)
tib.raw <- processLTBC(tib.raw,
                       lt.loc = "R:/RESRoberts/Bioinformatics/scRNAOuts/S0018xS0028/lt.fq",
                       cid.loc = "R:/RESRoberts/Bioinformatics/scRNAOuts/S0018xS0028/cid.fq",
                       histogram = T,
                       title = "Tibia, Top 40 Clones",
                       ymax = 1.75,
                       col.fill = "#00A087FF",
                       relative = T)
lung.raw <- processLTBC(lung.raw,
                        lt.loc = "R:/RESRoberts/Bioinformatics/scRNAOuts/S0024xS0029/lt.fq",
                        cid.loc = "R:/RESRoberts/Bioinformatics/scRNAOuts/S0024XS0029/cid.fq",
                        histogram = T,
                        title = "Lineage Barcode Enrichment by Microenvironment",
                        ymax = 1.75,
                        relative = T)
# 
# #Generate figure for paper with my scSeurat modified code
# p1 <- cx.LTBS$fig
# p1 <- p1 + ylim(0, 1.75)
# rm(cx.LTBS)
# 
# p2 <- tib.LTBS$fig 
# p2 <- p2 + ylim(0, 1.75)
# rm(tib.LTBS)
# 
# p3 <- lung.LTBS$fig 
# p3 <- p3 + ylim(0, 1.75)
# rm(lung.LTBS)
# 
# library(plotly)
# p4 <- subplot(p1, p2, p3, nrows = 3)

#Determine number of unique LTs
length((cx.LTBS$lt))
# [1] 3178
length(unique(cx.LTBS$lt))
# [1] 934

length((tib.LTBS$lt))
# [1] 2849
length(unique(tib.LTBS$lt))
# [1] 697

length((lung.LTBS$lt))
# [1] 4574
length(unique(lung.LTBS$lt))
# [1] 516

cx.raw <- cx.raw$sobject
tib.raw <- tib.raw$sobject
lung.raw <- lung.raw$sobject

#Subset all to #2800 cells in each condition 
cx.raw <- subset(cx.raw, cells = sample(Cells(cx.raw), 2800))
tib.raw <- subset(tib.raw, cells = sample(Cells(tib.raw), 2800))
lung.raw <- subset(lung.raw, cells = sample(Cells(lung.raw), 2800))

# Merge into a single Seurat object
os17 <- merge(cx.raw, y = c(tib.raw, lung.raw),
              add.cell.ids = c("Culture", "Tibia", "Lung"),
              project = "LineageTracing")

# Process and cluster
os17 <- NormalizeData(os17) %>%
  FindVariableFeatures(selection.method = "vst") %>%
  ScaleData() %>%
  RunPCA(pc.genes = os.17@var.genes, npcs = 20) %>%
  RunUMAP(reduction = "pca", dims = 1:20) %>%
  FindNeighbors(reduction = "pca", dims = 1:20) %>%
  FindClusters(resolution = 0.3)

# CCR
# Attempt to regress out the effects of cell cycle on these tumor cells
s.genes <- cc.genes$s.genes
g2m.genes <- cc.genes$g2m.genes
os17 <- CellCycleScoring(object = os17, s.features = s.genes,
                            g2m.features = g2m.genes, set.ident = TRUE)

os17 <- ScaleData(object = os17, vars.to.regress = c("S.Score", "G2M.Score"),
                  features = rownames(x = os17)) 
os17 <- RunPCA(os17, pc.genes = os.17@var.genes, npcs = 20) %>%
        RunUMAP(reduction = "pca", dims = 1:20) %>%
        FindNeighbors(reduction = "pca", dims = 1:20) %>%
        FindClusters(resolution = 0.3)
        
# os17 <- RunPCA(os17, pc.genes = os17@var.genes, npcs = 20)
# os17 <- RunHarmony(os17, group.by.vars = "src", plot_convergence = T)
# os17 <- RunUMAP(os17, reduction = "harmony", dims = 1:20)
# os17 <- FindNeighbors(os17, reduction = "harmony", dims = 1:20)
# os17 <- FindClusters(os17, resolution = 0.3)

# pdf("Harmony.pdf", width = 7, height = 7)
# DimPlot(os17, reduction = "umap", group.by = "src", pt.size = 1, label = F, order = cell.ids) + 
#   coord_fixed() + 
#   ggtitle("OS17 by Source") + 
#   scale_color_npg()
# dev.off()

# Plot the data 
set.seed(100)
cell.ids <- sample(colnames(os17))
DimPlot(os17, reduction = "umap", group.by = "src", pt.size = 1, label = F, order = cell.ids) + 
  coord_fixed() + 
  ggtitle("OS17 by Source") + 
  scale_color_npg()
DimPlot(os17, reduction = "umap", pt.size = 1, label = T) + 
  coord_fixed() + 
  ggtitle("OS17 Clusters") + 
  scale_color_npg(alpha = 0.7)

# Extract the barcode frequency lists
cx.lt.list <- processLTBC(cx.raw,
                          lt.loc = "R:/RESRoberts/Bioinformatics/scRNAOuts/S0016-zymo/lt.fq",
                          cid.loc = "R:/RESRoberts/Bioinformatics/scRNAOuts/S0016-zymo/cid.fq",
                          ret.list = T)
tib.lt.list <- processLTBC(tib.raw,
                           lt.loc = "R:/RESRoberts/Bioinformatics/scRNAOuts/S0018xS0028/lt.fq",
                           cid.loc = "R:/RESRoberts/Bioinformatics/scRNAOuts/S0018xS0028/cid.fq",
                           ret.list = T)
lung.lt.list <- processLTBC(lung.raw,
                            lt.loc = "R:/RESRoberts/Bioinformatics/scRNAOuts/S0024xS0029/lt.fq",
                            cid.loc = "R:/RESRoberts/Bioinformatics/scRNAOuts/S0024XS0029/cid.fq",
                            ret.list = T)

# Subset the three samples, but retain the current umap data
cx.sub <- subset(os17, subset = src == "Culture")
tib.sub <- subset(os17, subset = src == "Tibia")
lung.sub <- subset(os17, subset = src == "Lung")

# Generate cluster identification plots for the top 6 enriched clones from each sample
# Use colors from the npg palatte in ggsci
DimPlot(cx.sub, reduction = "umap", pt.size = 1, label = F, group.by = "src") + 
  coord_fixed() + 
  ggtitle("Culture Subset") + 
  scale_color_npg(alpha = 0.7)

for(i in 1:6) {
  p <- DimPlot(cx.sub, 
          reduction = "umap",
          pt.size = 1,
          cells.highlight = WhichCells(cx.sub, expression = lt == cx.lt.list[[i,1]]), 
          cols.highlight = "#E64B35FF",
          sizes.highlight = 3) + 
        coord_fixed() +
        theme(legend.position = "none") +
        ggtitle(paste("Culture Clone", cx.lt.list[[i,1]]))
  print(p)
}

DimPlot(tib.sub, reduction = "umap", pt.size = 1, label = F) + 
  coord_fixed() + 
  ggtitle("Tibia Subset") + 
  scale_color_npg(alpha = 0.7)

# Remove the little outlier bugger
tib.sub$remove = "Keep"
tib.sub$remove["Tibia_GCGGAAATCCTTATGT"] <- "Remove"
tib.sub <- subset(tib.sub, subset = remove == "Keep")

DimPlot(tib.sub, reduction = "umap", pt.size = 1, label = T) + 
  coord_fixed() + 
  ggtitle("Tibia Subset") + 
  scale_color_npg(alpha = 0.7)

p1 <- DimPlot(tib.sub, reduction = "umap", pt.size = 1, label = F, group.by = "src") + 
  coord_fixed() + 
  ggtitle("Tibia Subset") 
p1 + scale_color_manual(values = c("#00A087FF"))


for(i in 1:6) {
  p <- DimPlot(tib.sub, 
               reduction = "umap",
               pt.size = 1,
               cells.highlight = WhichCells(tib.sub, expression = lt == tib.lt.list[[i,1]]), 
               cols.highlight = "#E64B35FF",
               sizes.highlight = 3) + 
    coord_fixed() +
    theme(legend.position = "none") +
    ggtitle(paste("Tibia Clone", tib.lt.list[[i,1]]))
  print(p)
}

p2 <- DimPlot(lung.sub, reduction = "umap", pt.size = 1, label = F, group.by = "src") + 
  coord_fixed() + 
  ggtitle("Lung Subset") 
p2 + scale_color_manual(values = c("#4DBBD5FF"))

for(i in 1:6) {
  pdf(paste("plot", i, ".pdf", sep = ""))
  p <- DimPlot(lung.sub, 
               reduction = "umap",
               pt.size = 1,
               cells.highlight = WhichCells(lung.sub, expression = lt == lung.lt.list[[i,1]]), 
               cols.highlight = "#E64B35FF",
               sizes.highlight = 3) + 
    coord_fixed() +
    theme(legend.position = "none") +
    ggtitle(paste("Lung Clone", lung.lt.list[[i,1]])) +
    xlim(0,9) + NoLegend() + NoAxes()
  print(p)
  dev.off()
}

DimPlot(lung.sub, reduction = "umap", pt.size = 1, label = F) + 
  coord_fixed() + 
  ggtitle("Lung Subset") 

#Tryign to plot pdfs one after the other in a matrix

library("grid")
#Culture
vplayout <- function(x, y) viewport(layout.pos.row = x, layout.pos.col = y)
pdf("grid_cx_v1.pdf", width = 10, height = 10)
grid.newpage()
pushViewport(viewport(layout = grid.layout(1, 4)))
for (i in 1:4) {
  p <- DimPlot(cx.tagged, 
               reduction = "umap",
               pt.size = 1,
               cells.highlight = WhichCells(cx.sub, expression = lt == cx.lt.list[[i,1]]), 
               cols.highlight = "#E64B35FF",
               sizes.highlight = 3, order = cell.ids) + 
    coord_fixed() +
    theme(legend.position = "none") +
    ggtitle(paste("Clone", cx.lt.list[[i,1]])) +
    xlim(-12,-6) + NoLegend() + NoAxes()
  print(p, vp=vplayout(ceiling(i/4), i))
}
dev.off()

#Tibia
vplayout <- function(x, y) viewport(layout.pos.row = x, layout.pos.col = y)
pdf("grid_tib_v1.pdf", width = 10, height = 10)
grid.newpage()
pushViewport(viewport(layout = grid.layout(1, 4)))
for (i in 1:4) {
  p <- DimPlot(tib.tagged, 
               reduction = "umap",
               pt.size = 1,
               cells.highlight = WhichCells(tib.sub, expression = lt == tib.lt.list[[i,1]]), 
               cols.highlight = "#00A087FF",
               sizes.highlight = 3) + 
    coord_fixed() +
    theme(legend.position = "none") +
    ggtitle(paste("Clone", tib.lt.list[[i,1]])) +
    xlim(0,9) + NoLegend() + NoAxes()
  print(p, vp=vplayout(ceiling(i/4), i))
}
dev.off()

#Lung
vplayout <- function(x, y) viewport(layout.pos.row = x, layout.pos.col = y)
pdf("grid_lung_v4.pdf", width = 10, height = 10)
grid.newpage()
pushViewport(viewport(layout = grid.layout(1, 4)))
for (i in 1:4) {
  p <- DimPlot(lung.tagged, 
               reduction = "umap",
               pt.size = 1,
               cells.highlight = WhichCells(lung.sub, expression = lt == lung.lt.list[[i,1]]), 
               cols.highlight = "#4DBBD5FF",
               sizes.highlight = 3) + 
    coord_fixed() +
    theme(legend.position = "none") +
    ggtitle(paste("Clone", lung.lt.list[[i,1]])) +
    xlim(0,9) + NoLegend() + NoAxes()
  print(p, vp=vplayout(ceiling(i/4), i))
}
dev.off()

#Culture plots
pdf("Culture.pdf", width = 2.3, height = 2.3)
pcx <- DimPlot(cx.sub, reduction = "umap", pt.size = 1, label = F, group.by = "src") + 
  coord_fixed() + 
  ggtitle("Plate-derived") +
  xlim(-12,-6) + NoLegend() + NoAxes()
pcx + scale_color_manual(values = c("#E64B35FF"))
dev.off()

pdf("Tibia.pdf", width = 2.3, height = 2.3)
ptib <- DimPlot(tib.sub, reduction = "umap", pt.size = 1, label = F, group.by = "src") + 
  coord_fixed() + 
  ggtitle("Bone-derived")+
  xlim(0,9) + NoLegend() + NoAxes() 
ptib + scale_color_manual(values = c("#00A087FF"))
dev.off()

pdf("Lung.pdf", width = 2.3, height = 2.3)
plung <- DimPlot(lung.sub, reduction = "umap", pt.size = 1, label = F, group.by = "src") + 
  coord_fixed() + 
  ggtitle("Lung-derived") +
  xlim(0,9) + NoLegend() + NoAxes()
plung + scale_color_manual(values = c("#4DBBD5FF"))
dev.off()

#Together plot
pdf("All.pdf", width = 7, height = 7)
DimPlot(os17, reduction = "umap", group.by = "src", pt.size = 1, label = T) + 
  coord_fixed() +  
  scale_color_npg(alpha = 1)
dev.off()

DimPlot(os17, reduction = "umap", group.by = "src", pt.size = 1, label = T) + 
  coord_fixed() + 
  ggtitle("OS17 Clusters") + 
  scale_color_npg(alpha = 0.7)

save.image(file = "R:/RESRoberts/Bioinformatics/Analysis/Sanjana/2020/Preprocessed_Seurat_objects/OS17_Zymo_CTL.RData")

#Attempt to Make a vector that contains the column names (cell IDs) for all three of the samples, 
# then run a subset on the merged/source dataset with cells = that vector.

# cell.ids <- sample(colnames(os17))
# DimPlot(os17, reduction = "umap", group.by = "src", pt.size = 1, label = T, order = cell.ids) +
#   coord_fixed() +
#   ggtitle("OS17 by Source") +
#   scale_color_npg()

cx.cid <- colnames(cx.raw)
tb.cid <- colnames(tib.raw)
lung.cid <- colnames(lung.raw)

cx.cid <- paste("Culture_", cx.cid, sep="")
tb.cid <- paste("Tibia_", tb.cid, sep="")
lung.cid <- paste("Lung_", lung.cid, sep="")
comb.cids <- c(cx.cid, tb.cid, lung.cid)

os17.sub = subset(os17, cells = comb.cids)
cell.ids <- sample(colnames(os17.sub), 3000)
#cells(os17) is appended with "Culture_". Need to modify each of the vectors to contain that.

#Together plot
pdf("All.pdf", width = 8.5, height = 8.5)
DimPlot(os17.sub, reduction = "umap", group.by = "src", pt.size = 1, label = T) + 
  coord_fixed() +  
  scale_color_npg(alpha = 1)
dev.off()

DimPlot(os17.sub, reduction = "umap", group.by = "src", pt.size = 1, label = T) + 
  coord_fixed() + 
  ggtitle("OS17 Clusters") + 
  scale_color_npg(alpha = 0.7)

#IPA for enriched lineages
pdf("Lung.clusters.pdf", width = 2.3, height = 2.3)
DimPlot(lung.sub, reduction = "umap", pt.size = 1) + 
  coord_fixed() + 
  ggtitle("Lung-derived") +
  xlim(0,9) + NoLegend() + NoAxes()
dev.off()

#Assign identity to a particular lineage?

lung.lt.list[1:4,1]
# 039-074146
# 052-082154
# 037-078792
# 039-098388
head(FindMarkers(lung.sub, ident.1 = "CD14+ Mono", ident.2 = "FCGR3A+ Mono", logfc.threshold = log(2)))

#create a vector with cell IDs of freg(LT)= 1
LT <- vector(mode = "character")
for(i in 198:515){
temp <- WhichCells(lung.sub, expression = lt == lung.lt.list[[i,1]]) 
LT <- append(LT, temp)
}

LT.cells <- subset(lung.sub, cells = LT)
table(LT.cells$Phase)

#subset to cells that have a lineage tag
lung.LTcells <- vector(mode = "character")
for(i in 1:515){
  temp <- WhichCells(lung.sub, expression = lt == lung.lt.list[[i,1]]) 
  lung.LTcells <- append(lung.LTcells, temp)
}

lung.tagged <- subset(lung.sub, cells = lung.LTcells)

DimPlot(lung.tagged, reduction = "umap", pt.size = 1) + 
  coord_fixed() + 
  ggtitle("Lung-derived") +
  xlim(0,9) + NoLegend() + NoAxes()

#Lung
vplayout <- function(x, y) viewport(layout.pos.row = x, layout.pos.col = y)
pdf("grid_lung_v4.pdf", width = 10, height = 10)
grid.newpage()
pushViewport(viewport(layout = grid.layout(1, 4)))
for (i in 1:4) {
  p <- DimPlot(lung.tagged, 
               reduction = "umap",
               pt.size = 1,
               cells.highlight = WhichCells(lung.sub, expression = lt == lung.lt.list[[i,1]]), 
               cols.highlight = "#4DBBD5FF",
               sizes.highlight = 3) + 
    coord_fixed() +
    theme(legend.position = "none") +
    ggtitle(paste("Clone", lung.lt.list[[i,1]])) +
    xlim(0,9) + NoLegend() + NoAxes()
  print(p, vp=vplayout(ceiling(i/4), i))
}
dev.off()

#create a vector with cell IDs of freg(LT)= 1
LT <- vector(mode = "character")
for(i in 2){
  temp <- WhichCells(lung.tagged, expression = lt == lung.lt.list[[i,1]]) 
  LT <- append(LT, temp)
}

LT.cells <- subset(lung.sub, cells = LT)
df <- table(LT.cells$Phase)

ggplot(as.data.frame(df), aes(x = Var1, y = Freq)) +
  geom_bar(fill = "4DBBD5FF", stat = "identity") +
  ggtitle("Cell cycle distribution") +
  ylab("Count") +
  xlab("Phase")

#Combine 1 and 4
LT <- vector(mode = "character")
temp <- WhichCells(lung.sub, expression = lt == lung.lt.list[[1,1]]) 
LT <- append(LT, temp)
temp <- WhichCells(lung.sub, expression = lt == lung.lt.list[[4,1]])
LT <- append(LT, temp)

growth <- subset(lung.tagged, cells = LT)
DimPlot(lung.tagged)

FeaturePlot(lung.tagged, features = "POU5F1", pt.size = 1, cols = c("lightgray", "red2"))
FeaturePlot(lung.tagged, features = "NANOG", pt.size = 1, cols = c("lightgray", "red2"))
FeaturePlot(lung.tagged, features = "SOX2", pt.size = 1, cols = c("lightgray", "red2"))
FeaturePlot(lung.tagged, features = "KLF4", pt.size = 1, cols = c("lightgray", "red2"))
FeaturePlot(lung.tagged, features = "IL6", pt.size = 1, cols = c("lightgray", "red2"))
FeaturePlot(lung.tagged, features = "IL11", pt.size = 1, cols = c("lightgray", "red2"))
FeaturePlot(lung.tagged, features = "CXCL8", pt.size = 1, cols = c("lightgray", "red2"))
FeaturePlot(lung.tagged, features = "CDKN1A", pt.size = 1, cols = c("lightgray", "red2"))
FeaturePlot(lung.tagged, features = "MYC", pt.size = 1, cols = c("lightgray", "red2"))
FeaturePlot(lung.tagged, features = "TGFB1", pt.size = 1, cols = c("lightgray", "red2"))

Idents(lung.tagged, cells = LT) <- 'Enriched'
enr.markers=find.markers(lung.tagged,7,thresh.use = 2,test.use = "roc")

#Visualize these new markers with a violin plot
vlnPlot(nbt,c("CRABP1","LINC-ROR"))

# Find differentially expressed features between CD14+ and FCGR3A+ Monocytes
enr.markers <- FindMarkers(lung.tagged, ident.1 = "Enriched", ident.2 = NULL, min.pct = 0.5)
# view results
head(enr.markers)

install.packages("xlsx")
library("xlsx")
write.xlsx(enr.markers, file = "R:/RESRoberts/Bioinformatics/Analysis/Sanjana/2020/growth_markers.xlsx", 
           col.names = TRUE, row.names = TRUE, append = FALSE)

#Group 2
LT <- vector(mode = "character")
temp <- WhichCells(lung.sub, expression = lt == lung.lt.list[[2,1]]) 
LT <- append(LT, temp)

growth2 <- subset(lung.tagged, cells = LT)
DimPlot(lung.tagged)

Idents(lung.tagged, cells = LT) <- 'Enriched-2'

# Find differentially expressed features between CD14+ and FCGR3A+ Monocytes
enr.markers <- FindMarkers(lung.tagged, ident.1 = "Enriched-2", ident.2 = NULL, min.pct = 0.5)
# view results
head(enr.markers)

write.xlsx(enr.markers, file = "R:/RESRoberts/Bioinformatics/Analysis/Sanjana/2020/growth_02_markers.xlsx", 
           col.names = TRUE, row.names = TRUE, append = FALSE)
CEBPB
COL1A1
FOS
JUN
MCL1
NFKBIA
SOCS3
VEGFA

FeaturePlot(lung.tagged, features = "CEBPB", pt.size = 1, cols = c("lightgray", "red2"))
FeaturePlot(lung.tagged, features = "COL1A1", pt.size = 1, cols = c("lightgray", "red2"))
FeaturePlot(lung.tagged, features = "FOS", pt.size = 1, cols = c("lightgray", "red2"))
FeaturePlot(lung.tagged, features = "JUN", pt.size = 1, cols = c("lightgray", "red2"))
FeaturePlot(lung.tagged, features = "MCL1", pt.size = 1, cols = c("lightgray", "red2"))
FeaturePlot(lung.tagged, features = "NFKBIA", pt.size = 1, cols = c("lightgray", "red2"))
FeaturePlot(lung.tagged, features = "SOCS3", pt.size = 1, cols = c("lightgray", "red2"))
FeaturePlot(lung.tagged, features = "VEGFA", pt.size = 1, cols = c("lightgray", "red2"))

#Glycolysis
ENO1
ENO2
PFKP
PGK1
TPI1

FeaturePlot(lung.tagged, features = "ENO1", pt.size = 1, cols = c("lightgray", "red2"), min.cutoff = 2)
FeaturePlot(lung.tagged, features = "ENO2", pt.size = 1, cols = c("lightgray", "red2"), min.cutoff = 1)
FeaturePlot(lung.tagged, features = "PFKP", pt.size = 1, cols = c("lightgray", "red2"), min.cutoff = 0.2)
FeaturePlot(lung.tagged, features = "PGK1", pt.size = 1, cols = c("lightgray", "red2"), min.cutoff = 2)
FeaturePlot(lung.tagged, features = "TPI1", pt.size = 1, cols = c("lightgray", "red2"), min.cutoff = 3)

#Proceed to perform IPA on each Cluster and annotate

