library(httr)
library(jsonlite)
library(dplyr)
library(openxlsx)

API_KEY <- "API_KEY"
CHANNEL_ID <- "UCkinYTS9IHqOEwR1Sze2JTw"  # SBS 뉴스
MIN_VIEWS <- 500000
TARGET_VIDEOS <- 2500

# 업로드 플레이리스트 ID 찾기
url <- paste0(
  "https://www.googleapis.com/youtube/v3/channels?",
  "part=contentDetails&id=",
  CHANNEL_ID,
  "&key=", API_KEY
)

channel_data <- fromJSON(content(GET(url), "text", encoding = "UTF-8"))
uploads_id <- channel_data$items$contentDetails$relatedPlaylists$uploads

# 최근 2500개 영상 ID 수집
video_ids <- c()
next_token <- NULL

while(length(video_ids) < TARGET_VIDEOS){
  
  url2 <- paste0(
    "https://www.googleapis.com/youtube/v3/playlistItems?",
    "part=contentDetails",
    "&playlistId=", uploads_id,
    "&maxResults=50",
    if(!is.null(next_token))
      paste0("&pageToken=", next_token)
    else "",
    "&key=", API_KEY
  )
  
  data <- fromJSON(content(GET(url2), "text", encoding = "UTF-8"))
  
  video_ids <- c(
    video_ids,
    data$items$contentDetails$videoId
  )
  
  if(is.null(data$nextPageToken))
    break
  
  next_token <- data$nextPageToken
}

video_ids <- video_ids[1:min(TARGET_VIDEOS, length(video_ids))]

print(paste("수집한 영상 수:", length(video_ids)))

# 조회수 가져오기
result <- data.frame()

for(i in seq(1, length(video_ids), by = 50)){
  
  batch <- video_ids[i:min(i + 49, length(video_ids))]
  
  url3 <- paste0(
    "https://www.googleapis.com/youtube/v3/videos?",
    "part=snippet,statistics",
    "&id=", paste(batch, collapse = ","),
    "&key=", API_KEY
  )
  
  info <- fromJSON(content(GET(url3), "text", encoding = "UTF-8"))
  
  temp <- data.frame(
    title = info$items$snippet$title,
    views = as.numeric(info$items$statistics$viewCount),
    likes = as.numeric(info$items$statistics$likeCount),
    comments = as.numeric(info$items$statistics$commentCount),
    published = info$items$snippet$publishedAt,
    videoId = info$items$id
  )
  
  result <- bind_rows(result, temp)
}

# 영상 링크 추가
result <- result %>%
  mutate(
    url = paste0("https://www.youtube.com/watch?v=", videoId)
  )

# 50만 이상만 필터링
result_500k <- result %>%
  filter(views >= MIN_VIEWS) %>%
  arrange(desc(views))

print(paste("조회수 50만 이상 영상 수:", nrow(result_500k)))

write.xlsx(
  result_500k,
  "SBS_최근2500개_50만이상.xlsx"
)

print(result_500k)