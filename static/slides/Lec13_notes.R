library(tidyverse)

# GoT - Books ---------

books = jsonlite::read_json("https://www.anapioficeandfire.com/api/books?pageSize=20")

books |>
  tibble(books = _) |>
  unnest_wider(books) |>
  View()

# GoT - Houses ---------

# Try none, 100 etc. pageSize

houses = jsonlite::read_json("https://www.anapioficeandfire.com/api/houses")
houses = jsonlite::read_json("https://www.anapioficeandfire.com/api/houses?pageSize=100")


houses |>
  tibble(houses = _) |>
  unnest_wider(houses) |>
  View()

## Iteration ----------

full = list()
page = 1
repeat {
  message("Grabbing page", page)
  houses = jsonlite::read_json( paste0(
    "https://www.anapioficeandfire.com/api/houses?",
    "pageSize=50&page=", page
  ) )
  
  if (length(houses) == 0)
    break

  full = c(full, houses)
  page = page+1  
}

full |>
  tibble(houses = _) |>
  unnest_wider(houses) |>
  View()



## httr2 -----------

library(httr2)

resp = request("https://www.anapioficeandfire.com/api/houses") |>
  req_url_query(pageSize=50, page=1) |>
  #req_dry_run()
  req_perform()

resp |>
  resp_status()

resp |> 
  resp_body_json() |>
  tibble(houses = _) |>
  unnest_wider(houses) |>
  View()


## httr2 headers -------

resp |> 
  resp_headers()


resp |> 
  resp_header("link")
  

get_links = function(resp) {
  resp |>
    resp_header("link") |>
    str_match_all('<(.*?)>; rel="([a-zA-Z]+)"') |>
    (\(x) (setNames(as.list(x[[1]][,2]), x[[1]][,3])))()
}

get_links(resp)[["next"]]



req = request("https://www.anapioficeandfire.com/api/houses") |>
  req_url_query(pageSize=50, page=1)
  
resp = req_perform(req)
full = list()
page = 1

repeat {
  message("Grabbing page", page)
  full = c(full, resp_body_json(resp))
  
  links = get_links(resp)
  if (is.null(links[["next"]]))
    break
  
  req = req_url(req, links[["next"]])
  resp = req_perform(req)
  
  page = page+1
}

full |>
  tibble(houses = _) |>
  unnest_wider(houses) |>
  View()



## Wrapper function -------


aaoif = function(
  resource = c("root", "books", "characters", "houses"), ..., 
  base_url = "https://www.anapioficeandfire.com/api/", verbose = TRUE
) {
  resource = match.arg(resource)
  
  if (resource == "root")
    resource = ""
  
  url = paste0(base_url, resource)
  
  
  resp = request(url) |>
    req_url_query(...) |>
    req_perform()
  
  full = list()
  page = 1
  
  repeat {
    if (verbose) message("Grapping page", page)
    full = c(full, resp_body_json(resp))
    
    links = get_links(resp)
    if (is.null(links[["next"]]))
      break
    
    resp = request(links[["next"]]) |>
      req_perform()
    
    page = page+1
  }
  
  full |>
    tibble(data = _) |>
    unnest_wider(data)
}


h1 = aaoif("houses")
h2 = aaoif("houses", pageSize=50)

identical(h1, h2)

## Exercises ------

### 1.1 How many characters are included in this API? ----

c = aaoif("characters", pageSize=50)
nrow(c)

### 1.2. What percentage of the characters are dead? ----

sum(c$died != "") / nrow(c)

c_alive = aaoif("characters", pageSize=50, isAlive = TRUE)

(nrow(c) - nrow(c_alive)) / (nrow(c))

  
### 1.3. How many houses have an ancestral weapon? ----

h = aaoif("houses", pageSize=50)

has_weap = h$ancestralWeapons |>
  map(unlist) |>
  map_lgl(~ all(.x != ""))

sum(has_weap)


(h_weap = aaoif("houses", pageSize=50, hasAncestralWeapons = TRUE))



## GitHub example -----


### Org repos ------

request("https://api.github.com/orgs/sta323-sp24/repos") |>
  req_perform() |>
  resp_body_json() |>
  map_chr("full_name")

request("https://api.github.com/orgs/sta323-sp24/repos") |>
  req_auth_bearer_token(gitcreds::gitcreds_get()$password) |>
  req_perform() |>
  resp_body_json() |>
  map_chr("full_name")


### Create a gist ----

gist = request("https://api.github.com/gists") |>
  req_auth_bearer_token(gitcreds::gitcreds_get()$password) |>
  req_body_json( list(
    description = "Testing 1 2 3 ...",
    files = list("test.R" = list(content = "print('hello world')\n")),
    public = TRUE
  ) ) |>
  req_perform()

resp_body_json(gist)

resp_body_json(gist)$html_url
