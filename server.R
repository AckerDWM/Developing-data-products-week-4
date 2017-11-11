library(shiny)
library(dplyr)
library(tidyr)
library(reshape2)
library(ggplot2)
library(cowplot)
library(ggdendro)
library(gridExtra)
library(ggsci)
library(stringr)
library(randomForest)
library(caret)
df = readRDS("data.rds")

select_genes = function(df, gene_list) {
  valid_gene_list = T
  sapply(gene_list, function(gene) {
    if (gene %in% df$TargetID == F) {
      valid_gene_list <<- F
      print(paste("Gene name", gene, "not found.", sep=" "))
    }
  })
  if (valid_gene_list == F) return(NULL)
  return( subset(df, TargetID %in% gene_list) )
}

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  output$Plot <- renderPlot({
    
    chart_type = input$chart_type
    
    genes = input$caption %>%
        str_to_upper() %>%
        str_split(",") %>%
        sapply(str_trim, side="both") %>%
        c()
    
    if (chart_type == "Lifespan charts") {

      f1 = select_genes(df, genes) %>%
        group_by(TargetID) %>%
        mutate(normalized = scale(value/total_RNA) ) %>%
        ungroup() %>%
        ggplot(aes(Age, normalized, color=TargetID, fill=TargetID)) +
        geom_point() +
        geom_smooth(method="loess", span=.5, alpha=.2) +
        labs(x="Age [days]", y="Signal / total signal\n[z-score]") +
        theme(legend.title = element_blank()) +
        scale_color_npg() +
        scale_fill_npg()
      
      f2 = select_genes(df, genes) %>%
        group_by(TargetID) %>%
        mutate(normalized = scale(value/total_RNA) ) %>%
        ungroup() %>%
        ggplot(aes(Age, normalized, color=TargetID, fill=TargetID)) +
        facet_grid(Strain~Sex, labeller=label_both) +
        geom_point() +
        geom_smooth(method="loess", span=.5, alpha=.2) +
        labs(x="Age [days]", y="Signal / total signal\n[z-score]") +
        theme(legend.title = element_blank()) +
        scale_color_npg() +
        scale_fill_npg()
      
      grid.arrange(f1, f2)
    } 
    
    if (chart_type == "Correlation matrix") {
      
      p = select_genes(df, genes) %>%
        group_by(TargetID) %>%
        mutate(normalized = scale(value/total_RNA) ) %>%
        ungroup() %>%
        select(variable, TargetID, normalized) %>%
        spread(TargetID, normalized) %>%
        {.[,sapply(names(.), function(name) name %in% genes)]} %>%
        cor() %>%
        melt() %>%
        ggplot(aes(Var1, Var2, fill=value)) +
        geom_tile() +
        labs(fill="Correlation") +
        theme(
          axis.title = element_blank(),
          axis.text.x = element_text(angle=90, vjust=.5),
          legend.position = "top"
          ) +
        scale_fill_gradient2(low="blue", mid="white", high="red", midpoint=0, 
                             limits=c(-1,1), breaks=c(-1,0,1)) +
        coord_equal()
      
      clust = select_genes(df, genes) %>%
        group_by(TargetID) %>%
        mutate(normalized = scale(value/total_RNA) ) %>%
        ungroup() %>%
        select(variable, TargetID, normalized) %>%
        spread(TargetID, normalized) %>%
        {.[,sapply(names(.), function(name) name %in% genes)]} %>%
        cor() %>%
        dist() %>%
        hclust()
      
      dendro = ggdendrogram(clust, size = 2, rotate = T) + ggtitle("Similarity")
      
      g = grid.arrange(dendro, p, layout_matrix=rbind(c(1, 2)))
      print(g)
      
    }
    
    if (chart_type == "Predictivity charts") {
      
      X_data = select_genes(df, genes) %>%
        group_by(TargetID) %>%
        mutate(normalized = scale(value/total_RNA) ) %>%
        ungroup() %>%
        select(variable, TargetID, normalized, Age) %>%
        dcast(variable+Age~TargetID, value.var="normalized")
      
      train_idx = createDataPartition(X_data$Age, p=.6, list=F)
      train_data = X_data[train_idx,]
      test_data = X_data[-train_idx,]
      
      rf = randomForest(x=select(train_data, -Age, -variable), y=train_data$Age, importance=T)
      test_y = predict(rf, newdata = select(test_data, -Age, -variable))
      
      p1 = qplot(test_data$Age, test_y) +
        #geom_smooth(method="loess", span=.5) +
        xlab("True age [days]") +
        ylab("Fitted age [days]") +
        geom_smooth()
      
      p2 = rf$importance[,1] %>%
        melt() %>%
        mutate(Gene=rownames(.)) %>%
        mutate(value=scales::rescale(value, to=c(.1,1))) %>%
        mutate(Total=sum(value)) %>%
        mutate(`Relative importance`=value/Total) %>%
        ggplot(aes(reorder(Gene, -`Relative importance`), `Relative importance`)) +
        geom_bar(stat="identity") +
        theme(
          axis.text.x = element_text(angle=90, vjust=.5),
          axis.title.x = element_blank()
          )
      
      grid.arrange(p1, p2, nrow=1)
      
    }
    
  })
  
})
