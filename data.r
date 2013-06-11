library(sqldf)
datasets <- sqldf('
SELECT
  -- Identity
  "id", "name", "attribution",
  
  -- Other stuff
  "displayType", length("description") AS \'description.length\',

  -- Dates
  "createdAt", "publicationDate", "viewLastModified", "rowsUpdatedAt",

  -- Usage
  "viewCount", "downloadCount",
  
  -- Ownership
  "tableAuthor.screenName", "owner.roleName"
FROM dataset;',
  dbname = 'appgen.db',
  method = c(
    'character', 'character', 'factor',
    'factor', 'numeric',
    'numeric', 'numeric', 'numeric', 'numeric',
    'numeric', 'numeric',
    'factor', 'factor'
  )
)

datasets[c("createdAt", "publicationDate", "viewLastModified", "rowsUpdatedAt")] <-
  as.data.frame(lapply(datasets[c("createdAt", "publicationDate", "viewLastModified", "rowsUpdatedAt")], function(vec) {
    as.POSIXct(vec, origin = '1970-01-01')
  }))
