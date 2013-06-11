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
datasets[c("createdAt.week", "publicationDate.week", "viewLastModified.week", "rowsUpdatedAt.week")] <-
  lapply(datasets[c("createdAt", "publicationDate", "viewLastModified", "rowsUpdatedAt")], strftime, format = '%Y-%U')

# Coverage
day.range <- as.Date(range(na.omit(unique(as.vector(as.matrix(datasets[c("createdAt.day", "publicationDate.day", "viewLastModified.day", "rowsUpdatedAt.day")]))))))
all.days <- seq(day.range[1], day.range[2], by = "+1 day")
all.days <- seq(as.Date('2011-07-26'), day.range[2], by = "+1 day")

music <- adply(as.character(all.days), 1, function(day) {
  df <- subset(datasets, createdAt.day == day)
  data.frame(
    day = as.Date(day),
    n.created = sum(datasets$createdAt.day == day, na.rm = T),
    n.published = sum(datasets$publicationDate.day == day, na.rm = T),
    n.viewModified = sum(datasets$viewLastModified.day == day, na.rm = T),
    n.rowsUpdated = sum(datasets$rowsUpdatedAt.day == day, na.rm = T),
    prominent.department = names(sort(table(df$attribution), decreasing = T))[1],
    prominent.author = names(sort(table(df$tableAuthor.screenName), decreasing = T))[1],
    sum.description.length = sum(df$description.length),
    sum.viewCount = sum(df$viewCount),
    sum.downloadCount = sum(df$downloadCount),
    n.maps = sum(df$displayType == 'map', na.rm = T),
    n.tables = sum(df$displayType == 'table', na.rm = T),
    n.administrators = sum(df$owner.roleName == 'administrator', na.rm = T),
    n.publishers = sum(df$owner.roleName == 'publisher', na.rm = T)
  )
})
music$X1 <- NULL
rownames(music) <- music$day
