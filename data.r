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

# Most recent date
today <- as.POSIXct(max(datasets[c("createdAt", "publicationDate", "viewLastModified", "rowsUpdatedAt")], na.rm = T), origin = '1970-01-01')

# Datetimes
datasets[c("createdAt", "publicationDate", "viewLastModified", "rowsUpdatedAt")] <-
  as.data.frame(lapply(datasets[c("createdAt", "publicationDate", "viewLastModified", "rowsUpdatedAt")], function(vec) {
    as.POSIXct(vec, origin = '1970-01-01')
  }))

# Days
datasets[c("createdAt.day", "publicationDate.day", "viewLastModified.day", "rowsUpdatedAt.day")] <-
  lapply(datasets[c("createdAt", "publicationDate", "viewLastModified", "rowsUpdatedAt")], as.Date)

# Weeks 
# datasets[c("createdAt.week", "publicationDate.week", "viewLastModified.week", "rowsUpdatedAt.week")] <-
#   lapply(datasets[c("createdAt", "publicationDate", "viewLastModified", "rowsUpdatedAt")], strftime, format = '%Y-%U')

# Coverage
day.range <- as.Date(range(na.omit(unique(as.vector(as.matrix(datasets[c("createdAt.day", "publicationDate.day", "viewLastModified.day", "rowsUpdatedAt.day")]))))))
all.days <- seq(day.range[1], day.range[2], by = "+1 day")

music <- adply(as.character(all.days), 1, function(day) {
  c(day = day
  # created = nrow(subset(datasets, createdAt.day == day))
  )
})
