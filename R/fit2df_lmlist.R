fit2df.lmlist <- function(fit, condense=TRUE, metrics=FALSE, na.to.missing = TRUE, estimate.suffix="", ...){
	x = fit

	if (metrics==TRUE && length(x)>1){
		stop("Metrics only generated for single models: multiple models supplied to function")
	}

	df.out <- plyr::ldply(x, .id = NULL, function(x) {
		explanatory = names(coef(x))
		coef = round(coef(x), 2)
		ci = round(confint(x), 2)
		p = round(summary(x)$coef[,"Pr(>|t|)"], 3)
		df.out = data.frame(explanatory, coef, ci[,1], ci[,2], p)
		colnames(df.out) = c("explanatory", paste0("Coefficient", estimate.suffix), "L95", "U95", "p")
		return(df.out)
	})

	# Remove intercepts
	df.out = df.out[-which(df.out$explanatory =="(Intercept)"),]

	if (condense==TRUE){
		p = paste0("=", sprintf("%.3f", df.out$p))
		p[p == "=0.000"] = "<0.001"
		df.out = data.frame(
			"explanatory" = df.out$explanatory,
			"Coefficient" = paste0(sprintf("%.2f", df.out$Coefficient), " (", sprintf("%.2f", df.out$L95), " to ",
														 sprintf("%.2f", df.out$U95), ", p", p, ")"))
		colnames(df.out) = c("explanatory", paste0("Coefficient", estimate.suffix))
	}

	# Extract model metrics
	if (metrics==TRUE){
		x = fit[[1]]
		n_model = dim(x$model)[1]
		n_missing = length(summary(x)$na.action)
		n_data = n_model+n_missing
		n_model = dim(x$model)[1]
		loglik = round(logLik(x), 2)
		r.squared = signif(summary(x)$r.squared, 2)
		adj.r.squared = signif(summary(x)$adj.r.squared, 2)
		metrics.out = paste0(
			"Number in dataframe = ", n_data,
			", Number in model = ", n_model,
			", Missing = ", n_missing,
			", Log-likelihood = ", loglik,
			", R-squared = ", r.squared,
			", Adjusted r-squared = ", adj.r.squared)
	}

	if (metrics==TRUE){
		return(list(df.out, metrics.out))
	} else {
		return(df.out)
	}
}
