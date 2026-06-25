install.packages(c("openxlsx", "dplyr", "ggplot2"))

library(openxlsx)
library(dplyr)
library(ggplot2)

# 1. 엑셀 파일 불러오기
sbs <- read.xlsx("SBS_최근2500개_50만이상.xlsx")
kbs <- read.xlsx("KBS뉴스_최근2500개_50만이상.xlsx")
mbc <- read.xlsx("MBC뉴스_최근2500개_50만이상.xlsx")
ytn <- read.xlsx("YTN뉴스_최근2500개_50만이상.xlsx")

# 2. 채널명 추가
sbs$channel <- "SBS"
kbs$channel <- "KBS"
mbc$channel <- "MBC"
ytn$channel <- "YTN"

# 3. 데이터 합치기
news <- bind_rows(sbs, kbs, mbc, ytn)

# 4. 숫자형 변환
news <- news %>%
  mutate(
    views = as.numeric(views),
    likes = as.numeric(likes),
    comments = as.numeric(comments)
  )

# 5. 기본 요약
summary(news)

# 6. 채널별 영상 수
news %>%
  group_by(channel) %>%
  summarise(count = n())

# 7. 채널별 평균 조회수, 좋아요, 댓글
channel_summary <- news %>%
  group_by(channel) %>%
  summarise(
    count = n(),
    avg_views = mean(views, na.rm = TRUE),
    avg_likes = mean(likes, na.rm = TRUE),
    avg_comments = mean(comments, na.rm = TRUE)
  )

print(channel_summary)

# 8. 상관분석
cor_views_likes <- cor.test(news$views, news$likes)
cor_views_comments <- cor.test(news$views, news$comments)
cor_likes_comments <- cor.test(news$likes, news$comments)

print(cor_views_likes)
print(cor_views_comments)
print(cor_likes_comments)

# 9. 회귀분석: 좋아요와 댓글이 조회수에 영향을 주는가?
model <- lm(views ~ likes + comments, data = news)
summary(model)

# 10. 조회수-좋아요 산점도
ggplot(news, aes(x = views, y = likes, color = channel)) +
  geom_point(size = 3) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(
    title = "조회수와 좋아요 수의 관계",
    x = "조회수",
    y = "좋아요 수"
  )

# 11. 조회수-댓글 산점도
ggplot(news, aes(x = views, y = comments, color = channel)) +
  geom_point(size = 3) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(
    title = "조회수와 댓글 수의 관계",
    x = "조회수",
    y = "댓글 수"
  )

# 12. 채널별 평균 조회수 막대그래프
ggplot(channel_summary, aes(x = channel, y = avg_views)) +
  geom_col() +
  labs(
    title = "채널별 평균 조회수",
    x = "채널",
    y = "평균 조회수"
  )