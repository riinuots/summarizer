# Function to pull numbers and percentages out of Hmisc summary.formula function-------------------------
summary.factorlist <- function(df, dependent=dependent, explanatory=explanatory, p=FALSE, na.include=FALSE,
															 column=FALSE, total_col=FALSE, orderbytotal=FALSE){
	require(Hmisc)
	require(plyr)
	s <- summary.formula(as.formula(paste(dependent, "~", paste(explanatory, collapse="+"))), data = df,
											 method="reverse", overall=FALSE,
											 test=TRUE,na.include=na.include)
	df.out = ldply(s$stats, function(x){
		if(dim(x)[2] == 13){ #hack to get continuous vs categorical. Wouldn't work for factor with 13 levels
			# Continuous variables
			a = paste0(round(x[1,12], 1), " (", round(x[1,13], 1), ")")
			b = paste0(round(x[2,12], 1), " (", round(x[2,13], 1), ")")
			row1_name = dimnames(x)[[2]][12]
			row2_name = dimnames(x)[[2]][13]
			col1_name = dimnames(x)[[1]][1]
			col2_name = dimnames(x)[[1]][2]
			df.out = data.frame(paste0(row1_name, " (", row2_name, ")"), a, b)
			names(df.out) = c("levels", col1_name, col2_name)
			return(df.out)
		} else {
			# Factor variables
			row_name = dimnames(x)$w
			col1_name = dimnames(x)$g[1]
			col2_name = dimnames(x)$g[2]
			col1 = x[,1]
			col2 = x[,2]
			total = col1 + col2
			if (column == FALSE) {
				col1_prop = (col1/apply(x, 1, sum))*100 # row margin
				col2_prop = (col2/apply(x, 1, sum))*100
			} else {
				col1_prop = (col1/sum(col1))*100 # column margin
				col2_prop = (col2/sum(col2))*100
				total_prop = (total/sum(total))*100
			}
			a = paste0(col1, " (", sprintf("%.1f", round(col1_prop, 1)), ")") #sprintf to keep trailing zeros
			b = paste0(col2, " (", sprintf("%.1f", round(col2_prop, 1)), ")")
			if (total_col == FALSE){
				df.out = data.frame(row_name, a, b)
				names(df.out) = c("levels", col1_name, col2_name)
			} else if (total_col == TRUE & column == FALSE) {
				df.out = data.frame(row_name, a, b, total, total)
				names(df.out) = c("levels", col1_name, col2_name, "Total", "index_total")
			} else if (total_col == TRUE & column == TRUE) {
				df.out = data.frame(row_name, a, b, paste0(total, " (", sprintf("%.1f", round(total_prop, 1)), ")"), total)
				names(df.out) = c("levels", col1_name, col2_name, "Total", "index_total")
			}
		}
		return(df.out)
	})
	# Keep original order
	df.out$index = 1:dim(df.out)[1]

	if (p == TRUE){
		a = ldply(s$testresults, function(x) sprintf("%.3f",round(x[[1]], 3)))
		names(a) = c(".id", "pvalue")
		df.out = merge(df.out, a, by=".id")
	}

	# Add back in actual labels
	df.labels = data.frame(".id" = names(s$stats), "label" = s$labels)
	df.out.labels = merge(df.out, df.labels, by = ".id")
	if (orderbytotal==FALSE){
		df.out.labels = df.out.labels[order(df.out.labels$index),-1] # reorder columns and drop .id
	} else {
		df.out.labels = df.out.labels[order(-df.out.labels$index_total),-1] # reorder columns and drop .id
	}
	len = length(df.out.labels)
	df.out.labels = df.out.labels[,c((len), 1:(len-1))]
	return(df.out.labels)
}