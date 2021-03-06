library(sqldf)
library(plyr)
library(ddr)
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
    mean.description.length = mean(df$description.length),
    mean.viewCount = mean(df$viewCount),
    mean.downloadCount = mean(df$downloadCount),
    sd.description.length = sd(df$description.length),
    sd.viewCount = sd(df$viewCount),
    sd.downloadCount = sd(df$downloadCount),
    n.maps = sum(df$displayType == 'map', na.rm = T),
    n.tables = sum(df$displayType == 'table', na.rm = T),
    n.administrators = sum(df$owner.roleName == 'administrator', na.rm = T),
    n.publishers = sum(df$owner.roleName == 'publisher', na.rm = T)
  )
})
music$X1 <- NULL
rownames(music) <- music$day

# Convert means and sds into instruments.
music[c('mean.description.length','mean.viewCount','mean.downloadCount', 'sd.description.length','sd.viewCount','sd.downloadCount')] <-
  lapply(music[c('mean.description.length','mean.viewCount','mean.downloadCount', 'sd.description.length','sd.viewCount','sd.downloadCount')], function(vec) {
    vec[is.na(vec) | is.nan(vec)] <- median(vec, na.rm = T)
    vec
  })

music[c('mean.description.length','mean.viewCount','mean.downloadCount')] <-
  lapply(music[c('mean.description.length','mean.viewCount','mean.downloadCount')], function(vec) {
    vec[vec > 100] <- 100
    vec
  })

music[c('sd.description.length','sd.viewCount','sd.downloadCount')] <-
  lapply(music[c('sd.description.length','sd.viewCount','sd.downloadCount')], function(vec) {
    vec <- sqrt(vec)
    vec[vec > 10] <- 10
    vec
  })

# Drum beat
beat.dynamics <- c(t(data.frame(
  one   = music$n.created / max(music$n.created),
  two   = music$n.published / max(music$n.published),
  three = music$n.viewModified / max(music$n.viewModified),
  four  = music$n.rowsUpdated / max(music$n.rowsUpdated)
))) ^ (1/4)

# Always make a sound
beat.dynamics <- sapply(beat.dynamics, function(x) { max(x, 0.1)})
downbeat <- (seq_along(beat.dynamics) %% 4) == 1
beat.dynamics[downbeat] <- sapply(beat.dynamics[downbeat], function(x) { max(x, 0.2)})

# Melodies
melody.pitches <- ddply(music, 'day', function(day) {
  data.frame(
    description.length = rnorm(4, mean = day$mean.description.length, sd = day$sd.description.length),
    viewCount = rnorm(4, mean = day$mean.viewCount, sd = day$sd.viewCount),
    downloadCount = rnorm(4, mean = day$mean.downloadCount, sd = day$sd.downloadCount)
  )
})

# Chords
beat.chords <- data.frame(
  nyc = rep(music$prominent.author == 'NYC OpenData', each = 4),
  albert = rep(music$prominent.author == 'Albert Webber', each = 4),
  gary = rep(music$prominent.author == 'Gary A', each = 4)
)
beat.chords$other <- 0 == rowSums(beat.chords)


# Compose
ddr_init(player="/usr/bin/env mplayer'")

# Beat
wavs <- list(roland$SD1, roland$SD0)

down.beat <- up.beat <- beat.dynamics[1:50]
down.beat[(seq_along(down.beat) %% 2) == 1] <- 0
up.beat[(seq_along(up.beat) %% 2) == 0] <- 0
seqs <- list(down.beat, up.beat)

beat <- sequence(wavs, seqs, bpm = 120, count = 1/4)
writeWave(beat, 'beat.wav')

# Melody
melody.description <- arpeggidata(melody.pitches[1:200,'description.length'], blip)
writeWave(melody.description, 'melody-description.wav')
melody.viewCount <- arpeggidata(melody.pitches[1:200,'viewCount'], piano)
writeWave(melody.viewCount, 'melody-viewCount.wav')
# melody.downloadCount <- arpeggidata(melody.pitches[1:200,'downloadCount'], )
# writeWav(melody, 'melody-downloadCount.wav')

