library(sqldf)
datasets <- sqldf('
SELECT
  -- Identity
  "id", "name", "description", "attribution", "displayType",

  -- Dates
  "createdAt", "publicationDate", "viewLastModified", "rowsUpdatedAt",

  -- Usage
  "viewCount", "downloadCount",
  
  -- Ownership
  "tableAuthor.screenName", "owner.roleName"
FROM dataset;
', dbname = 'appgen.db')
