library(sqldf)
datasets <- sqldf('select "publicationDate", "viewLastModified", "id", "createdAt", "displayType", "attribution", "description", "viewCount", "name", "downloadCount", "rowsUpdatedAt", "tableAuthor.screenName", "owner.roleName" from dataset limit 3;', dbname = 'appgen.db')
