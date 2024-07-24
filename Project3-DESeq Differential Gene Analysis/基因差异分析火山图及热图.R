#### 导入包
library(ggplot2)
library(stringr)  
library(dplyr)  
library(pheatmap)
library(ggvenn)

#### 设置工作路径并导入数据
### 设置的工作路径
setwd("E:/work/项目/项目-大连姚文厚-肺癌预测复发转移/新思路_6月4日/图3. Deseq差异基因及分析/transcriptome/Lymphocyte_diff_gene_expression/")

### 不同方法的差异分析结果
edger<-read.csv("DEG.edger.result.csv",row.names = 1)
deseq2<-read.csv("DEG.deseq2.result.csv",row.names = 1)

### 表达数据
count<-read.csv("count.csv",row.names = 1)
count <- count[,1:19531]

## 筛选表达数据，并整理分组
clini_group <-read.csv("Lymphocyte_group.csv",row.names = 1)
high_names <- rownames(clini_group[clini_group$group=="High", ])
low_names <- rownames(clini_group[clini_group$group=="Low", ])
count_high <- count[rownames(count) %in% high_names, ]
count_high$group <- "High"
count_low <- count[rownames(count) %in% low_names, ]
count_low$group <- "Low"
count_data <- rbind(count_high, count_low)
df_count_data <- as.data.frame(t(count_data) )


#### 设置pvalue和logFC的阈值
cut_off_pvalue = 0.05
cut_off_logFC = 1


#### edger
### 绘制火山图
## 根据阈值分别为上调基因设置‘up’，下调基因设置‘Down’，无差异设置‘None’，保存到change列
# 这里的change列用来设置火山图点的颜色
edger$Sig = ifelse(edger$adj.P.Val < cut_off_pvalue & 
                   abs(edger$logFC) >= cut_off_logFC, 
                 ifelse(edger$logFC> cut_off_logFC ,'Up','Down'),'None')

# 查看下差异基因个数，如果基因个数过多，cutoff 可以设严格一些，如果过少就设置低一些
table(edger$Sig)

#绘图
ggplot(edger, aes(x = logFC, y = -log10(adj.P.Val), colour=Sig)) +
  geom_point(alpha=0.4, size=3.5) +
  scale_color_manual(values=c("#546de5", "#d2dae2","#ff4757"))+
  # 辅助线
  geom_vline(xintercept=c(-1,1),lty=4,col="black",lwd=0.8) +
  geom_hline(yintercept = -log10(cut_off_pvalue),
             lty=4,col="black",lwd=0.8) +
  # 坐标轴
  labs(x="log2(Fold Change)",
       y="-log10 (P-value)")+
  theme_bw()+
  ggtitle("Volcano Plot")+
  # 图例
  theme(plot.title = element_text(hjust = 0.5), 
        legend.position="right", 
        legend.title = element_blank()
  )
ggsave("edger火山图.pdf", height = 5, width = 5)

### 绘制热图
edger_opt <- edger %>% filter(Sig != "None")
exp_heatmap <- df_count_data %>% filter(rownames(df_count_data) %in% rownames(edger_opt))
exp_heatmap_numeric <- as.data.frame(sapply(exp_heatmap, function(x) as.numeric(as.character(x))))
annotation_col <- as.data.frame(t(df_count_data[19532,]))
p1<-pheatmap(exp_heatmap_numeric, 
             show_colnames = F, 
             show_rownames = F,
             scale = "row",
             cluster_cols = F,
             annotation_col = annotation_col,
             breaks = seq(-1, 1, length.out = 100)) 
ggsave(filename ="edger热图.pdf", plot = p1, device = "pdf", width = 5,height = 5 )


#### deseq2
### 绘制火山图
## 根据阈值分别为上调基因设置‘up’，下调基因设置‘Down’，无差异设置‘None’，保存到change列
# 这里的change列用来设置火山图点的颜色
deseq2$Sig = ifelse(deseq2$adj.P.Val < cut_off_pvalue & 
                     abs(deseq2$logFC) >= cut_off_logFC, 
                   ifelse(deseq2$logFC> cut_off_logFC ,'Up','Down'),'None')

# 查看下差异基因个数，如果基因个数过多，cutoff 可以设严格一些，如果过少就设置低一些
table(deseq2$Sig)

#绘图
ggplot(deseq2, aes(x = logFC, y = -log10(adj.P.Val), colour=Sig)) +
  geom_point(alpha=0.4, size=3.5) +
  scale_color_manual(values=c("#546de5", "#d2dae2","#ff4757"))+
  # 辅助线
  geom_vline(xintercept=c(-1,1),lty=4,col="black",lwd=0.8) +
  geom_hline(yintercept = -log10(cut_off_pvalue),
             lty=4,col="black",lwd=0.8) +
  # 坐标轴
  labs(x="log2(Fold Change)",
       y="-log10 (P-value)")+
  theme_bw()+
  ggtitle("Volcano Plot")+
  # 图例
  theme(plot.title = element_text(hjust = 0.5), 
        legend.position="right", 
        legend.title = element_blank()
  )
ggsave("deseq2火山图.pdf", height = 5, width = 5)

### 绘制热图
deseq2_opt <- deseq2 %>% filter(Sig != "None")
exp_heatmap <- df_count_data %>% filter(rownames(df_count_data) %in% rownames(deseq2_opt))
exp_heatmap_numeric <- as.data.frame(sapply(exp_heatmap, function(x) as.numeric(as.character(x))))
annotation_col <- as.data.frame(t(df_count_data[19532,]))
p1<-pheatmap(exp_heatmap_numeric, 
             show_colnames = F, 
             show_rownames = F,
             scale = "row",
             cluster_cols = F,
             annotation_col = annotation_col,
             breaks = seq(-1, 1, length.out = 100)) 
ggsave(filename ="deseq2热图.pdf", plot = p1, device = "pdf", width = 5,height = 5 )


#### 绘制两种方法的交集的热图 
###取交集
all_degs <- intersect(rownames(edger_opt), rownames(deseq2_opt))

### 依据三个包得到的差异基因绘制韦恩图
all_degs_venn <- list(DESeq2 = rownames(deseq2_opt), edgeR = rownames(edger_opt))
all_degs_venn <- ggvenn(all_degs_venn)
ggsave(filename = "all_degs_venn.pdf", plot = all_degs_venn, device = "pdf", width = 5, height = 5)

### 绘制共同差异基因的热图
exp_all_heatmap <- df_count_data %>% filter(rownames(df_count_data) %in% all_degs)
exp_all_heatmap_numeric <- as.data.frame(sapply(exp_all_heatmap, function(x) as.numeric(as.character(x))))
annotation_col <- as.data.frame(t(df_count_data[19532,]))
p1 <- pheatmap(exp_all_heatmap_numeric, 
               show_colnames = F, 
               show_rownames = F,
               scale = "row",
               cluster_cols = F,
               annotation_col = annotation_col,
               breaks = seq(-1, 1, length.out = 100)) 
ggsave(filename = "两种方法共同差异基因热图.pdf", plot = p1, device = "pdf", width = 5, height = 5)
dev.off()

### 保存挑选好的差异基因
write.csv(exp_all_heatmap, "挑选的基因.csv", row.names = T)













#### 根据EnhancedVolcano包自动生成火山图
library(EnhancedVolcano)
EnhancedVolcano(DEG,
                lab = rownames(DEG),
                labSize = 2,
                x = "logFC",
                y = "adj.P.Val",
                #selectLab = rownames(lrt)[1:4],
                xlab = bquote(~Log[2]~ "Fold Change"),
                ylab = bquote(~-Log[10]~italic(P)),
                pCutoff = cut_off_pvalue,## pvalue闃堝€?
                FCcutoff = cut_off_logFC,## FC cutoff
                xlim = c(-5,5),
                ylim = c(0,30),
                colAlpha = 0.6,
                legendLabels =c("NS","Log2 FC"," P-value",
                                " P-value & Log2 FC"),
                legendPosition = "top",
                legendLabSize = 10,
                legendIconSize = 3.0,
                pointSize = 1.5,
                title ="Volcano Plot",
                subtitle = 'EnhancedVolcano'
)
