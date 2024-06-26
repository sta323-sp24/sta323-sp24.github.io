library(rvest)
library(tidyverse)

## Example
url = "http://www.rottentomatoes.com/"

(session = polite::bow(url))

page = polite::scrape(session)


movies = tibble::tibble(
  title = page |> 
    html_elements(".dynamic-text-list__streaming-links+ ul .dynamic-text-list__item-title") |>
    html_text2(),
  tomatometer = page |>
    html_elements(".dynamic-text-list__streaming-links+ ul .b--medium") |>
    html_text2() |>
    str_remove("%$") |>
    as.numeric() |>
    (\(x) x/100)(),
  status = page |>
    html_elements(".dynamic-text-list__streaming-links+ ul .icon--tiny") |>
    html_attr("class") |>
    str_remove("icon ") |>
    str_remove("icon--tiny ") |>
    str_remove("icon__"),
  url = page |> 
    html_elements(".dynamic-text-list__streaming-links+ ul li a.dynamic-text-list__tomatometer-group") |>
    html_attr("href") |>
    (\(x) paste0(url, x))()
)


## Exercise 1

scrape_movie_page = function(url) {
  
  message("Scraping ", url)  
  
  page = polite::nod(session, url) |>
    polite::scrape()
  
  list(
    mpaa_rating = page |>
      html_elements(".info-item:nth-child(1) span") |>
      html_text2() |>
      str_remove(" \\(.*\\)"),
    
    runtime = page |>
      html_elements(".info-item:nth-child(10) time") |>
      html_text2(),
    
    tomatometer_score = page |>
      html_elements("#scoreboard") |>
      html_attr("tomatometerscore") |>
      as.integer(),
    
    audience_score = page |>
      html_elements("#scoreboard") |>
      html_attr("audiencescore") |>
      as.integer(),

    n_reviews = page |>
      html_elements('#scoreboard > a[data-qa="tomatometer-review-count"]') |>
      html_text2() |>
      str_remove(" Reviews") |>
      as.integer()
  )
}

movies = movies |>
  mutate(
    details = purrr::map(url, scrape_movie_page)
  ) |>
  unnest_wider(details)




