rm(list = ls())
# 设置工作路径
setwd("C:/Users/thecat/Desktop/图6. 差异基因的筛选及预后建模/通路分数/")

# 读取数据
df<-read.csv("通路分数_5.csv",row.names = 1)

# 加载数据包
library(survminer)  
library(survival)

#使用surv_cutpoint函数确定最佳阈值
cutpoint_result <- surv_cutpoint(data = df, 
                                 time = "futime", 
                                 event = "fustat", 
                                 variable = "HALLMARK_UV_RESPONSE_DN")

# 打印结果查看最佳阈值  
print(cutpoint_result)
# 最佳阈值已经确定并存储在best_cutpoint变量中  
best_cutpoint <- cutpoint_result$cutpoint$cutpoint


# 创建一个新的分组变量  
df$variable_group <- ifelse(df$HALLMARK_UV_RESPONSE_DN <= best_cutpoint, "Low", "High")  


# 拟合生存模型  
fit <- survfit(Surv(futime, fustat) ~ variable_group, data = df)

# 绘制生存曲线  
ggsurvplot(fit, 
           data = df,
           size = 1,                 
           palette = c("#E7B800", "#2E9FDF"),
           xlab = "Time in days",
           conf.int = TRUE,          
           pval = TRUE,              
           pval.method = TRUE,       
           log.rank.weights = "1",
           conf.int.style = "step", 
           legend.labs = c("High", "Low"),  
           ggtheme = theme_light()
)
ggsave("HALLMARK_UV_RESPONSE_DN生存曲线.pdf", width = 6, height = 5)
dev.off()
