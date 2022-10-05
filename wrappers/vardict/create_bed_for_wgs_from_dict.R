library(data.table)

#args <- c("/mnt/ssd/ssd_3/references/homsap/GRCh38-p10/seq/GRCh38-p10.dict","/mnt/ssd/ssd_3/references/homsap/GRCh38-p10/intervals/wgs/wgs.bed")

args <- commandArgs(trailingOnly = T)

input_file <- args[1]
output_bed <- args[2]

window <- 5000000
overlap <- 150

tab <- fread(input_file,skip = "@SQ",select = c(2,3),header = F)
tab[,V2 := gsub("SN:","",V2,fixed = T)]
tab[,V3 := as.integer(gsub("LN:","",V3,fixed = T))]

new_tab <- tab[V3 >= window + overlap,c(seq(window,V3,by = window) - 1,V3),by = V2]
new_tab[,V3 := c(0,head(V1,-1) + overlap + 1),by = V2]
setcolorder(new_tab,c(1,3,2))

new_tab <- rbind(new_tab,tab[V3 < window + overlap,list(V2,V3 = 0,V1 = V3 - 1)])
new_tab <- new_tab[order(match(V2, tab$V2))]

dir.create(dirname(output_bed),recursive = T,showWarnings = F)
options(scipen=99)
fwrite(new_tab,file = output_bed,sep = "\t",col.names = F)
options(scipen=0)
