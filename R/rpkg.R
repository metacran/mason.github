
#' This is a Mason template for a generic R package
#'
#' The template somewhat leans towards GitHub, actually,
#' so it is best for packages developed at GitHub.
#'
#' @export
#' @importFrom ask questions
#' @importFrom falsy try_quietly
#' @importFrom whoami gh_username username

survey <- questions(

  ## DESCRIPTION file
  name = input("Package name:", default = basename(getwd()),
    nextline = FALSE),
  title = input("Title:", default = answers$name, nextline = FALSE),
  version = input("Version:", default = "1.0.0", nextline = FALSE),
  author = input("Author:", default = default_author()),
  maintainer = input("Maintainer:", default = default_maintainer(answers)),
  description = input("Description:", default = answers$title),

  license = choose("License:", licenses, default = "MIT + file LICENSE"),
  need_license = constant(value = grepl(" file LICENSE", answers$license)),
  licensenofile = constant(value = sub(" + file LICENSE", "", answers$license)),
  copyrightholder = input("Copyright holder(s):", default = answers$author,
    when = function(a) isTRUE(a$needs_license)),

  gh_username = input("GitHub username:", default = username(),
    nextline = FALSE),

  url = input("URL:", default = default_url(answers)),
  bugreports = input("BugReports:", default = default_bugreports(answers)),

  ## Others
  testing = choose("Testing framework:", choices = c("testthat", "none"),
    default = 1),
  readme = confirm("README.md file:", default = TRUE),
  readme_rmd = confirm("README.Rmd file:", default = TRUE,
    when = function(a) isTRUE(a$readme)),
  news = confirm("NEWS.md file:", default = TRUE),
  cis = checkbox("Continuous integration:", choices = cis,
    default = c("Travis", "Appveyor")),
  travis_shield = constant(value = 'Travis' %in% answers$cis),
  appveyor_shield = constant(value = 'Appveyor' %in% answers$cis),

  ## git and GitHub stuff
  create_git_repo = confirm("Create git repo?", default = TRUE),
  create_gh_repo = confirm("Create repo on GitHub?", default = TRUE,
    when = function(a) isTRUE(a$create_git_repo)),

  push_to_github = confirm("Push initial version to GitHub?",
    default = FALSE, when = function(a) isTRUE(a$create_gh_repo)),

  ## Some constants
  year = constant(value = format(Sys.Date(), "%Y"))
)

licenses <- c("MIT + file LICENSE",
              "AGPL-3",
              "Artistic-2.0",
              "BSD_2_clause + file LICENSE",
              "BSD_3_clause + file LICENSE",
              "GPL-2",
              "GPL-3",
              "LGPL-2",
              "LGPL-2.1",
              "LGPL-3",
              "Other")

cis <- c("Travis", "Appveyor")

#' @importFrom whoami fullname
#' @importFrom falsy try_quietly %||%

try_gh_username <- function() {
  try_quietly(gh_username()) %||% ""
}

default_author <- function() {
  try_quietly(fullname()) %||% ""
}

#' @importFrom whoami email_address
#' @importFrom falsy try_quietly

default_maintainer <- function(answers) {
  n <- default_author() %||% answers$author
  e <- try_quietly(email_address()) %||% ""
  paste0(n, " <", e, ">")
}

#' @importFrom whoami gh_username

default_url <- function(answers) {
  gh <- answers$gh_username
  name <- answers$name
  paste0("https://github.com/", gh, "/", name)
}

default_bugreports <- function(answers) {
  paste0(answers$url, "/issues")
}

## ---------------------------------------------------------------------

#' @rdname survey
#' @export
#' @importFrom httr POST stop_for_status
#' @importFrom mason add_dependency
#' @param answers The answers the builder operates on.

build <- function(answers) {

  ## Add testthat to Suggests, if requested
  if ('testthat' %in% answers$testing) {
    add_dependency("Suggests", "testthat")
  }

  ## Remove LICENSE file if not needed
  if (! isTRUE(answers$need_license)) unlink("LICENSE")

  ## Remove testthat files if not used
  if (! 'testthat' %in% answers$testing) {
    unlink("tests/testthat.R")
    unlink("tests/testthat", recursive = TRUE)
  }

  ## Of no testing at all, remove 'tests' dir
  if (answers$testing == "none") {
    unlink("tests", recursive = TRUE)
  }

  ## Remove README file(s) if not requested
  if (! isTRUE(answers$readme_rmd)) {
    unlink("README.Rmd")
    unlink("Makefile")
  }
  if (! isTRUE(answers$readme)) {
    unlink("README.Rmd")
    unlink("README.md")
  }

  ## Remove NEWS.md if not requested
  if (! isTRUE(answers$news)) {
    unlink("NEWS.md")
  }

  ## Remove CI files if not requested
  if (! "Travis" %in% answers$cis) {
    unlink(".travis.yml")
  }
  if (! "Appveyor" %in% answers$cis) {
    unlink("appveyor.yml")
  }

  ## Remove .gitignore if no git repo is created
  if (! isTRUE(answers$create_git_repo)) {
    unlink(".gitignore")
  }

  ## Create Git/GitHub repos, this must be the last one
  ## to include all changes
  if (isTRUE(answers$create_git_repo)) {
    ok <- create_git_repo(answers)
    if (!inherits(ok, "try-error") && isTRUE(answers$create_gh_repo)) {
      token <- Sys.getenv("GITHUB_TOKEN")
      create_gh_repo(answers, token)
    }
  }

}

create_git_repo <- function(answers) {
  try({
    system("git init .", intern = TRUE)
    system("git add .", intern = TRUE)
    system("git commit -m \"Initial commit of Mason template\"", intern = TRUE)
  })
}

#' @importFrom httr POST add_headers status_code

create_gh_repo <- function(answers, token) {

  if (token != "") {
    url <- "https://api.github.com/user/repos"
    auth <- c("Authorization" = paste("token", token))
    data <- paste0('{ "name": "', answers$name, '",',
                   '   "description": "', answers$title, '" }')
    response <- POST(
      url,
      body = data,
      add_headers("user-agent" = "https://github.com/gaborcsardi/mason",
                  'accept' = 'application/vnd.github.v3+json',
                  .headers = auth)
    )

    sc <- status_code(response)
    if (sc == 422) {
      warning("GitHub repository already exists")

    } else if (sc != 201) {
      warning("Could not create GitHub repository")
    }
  }

  remote_ok <- try({
    cmd <- paste0("git remote add origin git@github.com:",
                  answers$gh_username, "/", answers$name, ".git")
    system(cmd, intern = TRUE)
  })

  if (!inherits(remote_ok, "try-error") && isTRUE(answers$push_to_github)) {
    try({
      system("git push -u origin master", intern = TRUE)
    })
  }
}
