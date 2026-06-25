library(httr)
library(jsonlite)
library(dplyr)
library(openxlsx)

API_KEY <- "API_KEY"
HANDLE <- "MBCNEWS11"   # https://www.youtube.com/@MBCNEWS11/videos
MIN_VIEWS <- 500000
TARGET_VIDEOS <- 2500

# 채널 정보 가져오기
res <- GET(
  "https://www.googleapis.com/youtube/v3/channels",
  query = list(
    part = "contentDetails,snippet",
    forHandle = HANDLE,
    key = API_KEY
  )
)

channel_data <- fromJSON(
  content(res, "text", encoding = "UTF-8"),
  flatten = TRUE
)

uploads_id <- channel_data$items$contentDetails.relatedPlaylists.uploads

print(paste("업로드 플레이리스트:", uploads_id))

# 최근 1500개 영상 ID 수집
video_ids <- c()
next_token <- NULL

while(length(video_ids) < TARGET_VIDEOS){
  
  res2 <- GET(
    "https://www.googleapis.com/youtube/v3/playlistItems",
    query = list(
      part = "contentDetails",
      playlistId = uploads_id,
      maxResults = 50,
      pageToken = next_token,
      key = API_KEY
    )
  )
  
  data <- fromJSON(
    content(res2, "text", encoding = "UTF-8"),
    flatten = TRUE
  )
  
  video_ids <- c(
    video_ids,
    data$items$contentDetails.videoId
  )
  
  if(is.null(data$nextPageToken))
    break
  
  next_token <- data$nextPageToken
}

video_ids <- video_ids[
  1:min(TARGET_VIDEOS, length(video_ids))
]

print(paste("수집한 영상 수:", length(video_ids)))

# 영상 정보 가져오기
result <- data.frame()

for(i in seq(1, length(video_ids), by = 50)){
  
  batch <- video_ids[
    i:min(i + 49, length(video_ids))
  ]
  
  res3 <- GET(
    "https://www.googleapis.com/youtube/v3/videos",
    query = list(
      part = "snippet,statistics",
      id = paste(batch, collapse = ","),
      key = API_KEY
    )
  )
  
  info <- fromJSON(
    content(res3, "text", encoding = "UTF-8"),
    flatten = TRUE
  )
  
  temp <- data.frame(
    title = info$items$snippet.title,
    views = as.numeric(info$items$statistics.viewCount),
    likes = as.numeric(info$items$statistics.likeCount),
    comments = as.numeric(info$items$statistics.commentCount),
    published = info$items$snippet.publishedAt,
    videoId = info$items$id
  )
  
  result <- bind_rows(result, temp)
}

# 링크 추가
result <- result %>%
  mutate(
    url = paste0(
      "https://www.youtube.com/watch?v=",
      videoId
    )
  )

# 조회수 50만 이상만 추출
result_500k <- result %>%
  filter(views >= MIN_VIEWS) %>%
  arrange(desc(views))

print(
  paste(
    "조회수 50만 이상 영상 수:",
    nrow(result_500k)
  )
)

write.xlsx(
  result_500k,
  "MBC뉴스_최근2500개_50만이상.xlsx",
)

print(result_500k)