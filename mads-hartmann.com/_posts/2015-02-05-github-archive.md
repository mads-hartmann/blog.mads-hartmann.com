---
layout: post
title: "Github Archive"
date: 2015-02-05 21:08:52
---

I recently thought it would be cool to show a list, here on the blog, of all
the projects that I've contributed to on Github. I googled around a bit and
found this [Stack Overflow
answer](http://stackoverflow.com/questions/20714593/github-api-repositories-contributed-to#answer-27643444).

It turns out that Github has a project named [Github
Archive](https://www.githubarchive.org) which stores all public activity on
Github dating back to 2011-02-12. What is even cooler is that this dataset is
available on [Google Big-query](https://bigquery.cloud.google.com/) and it's
updated by the hour!

I looked through the
[documentation](https://developer.github.com/v3/activity/events/types/#pullrequestevent)
of the event I was interested in (`PullRequestEvent`) and modified the query
from the SO answer slightly to also return the programming language of the
repository and the date of the my latest pull request. I ended up with the
following query. Keep in mind that this query only works for data before 2015.
See note at the bottom for more information.

```sql
SELECT
  repository_url,
  LAST(created_at) AS last_pr,
  LAST(repository_language) as language
FROM [githubarchive:github.timeline]
WHERE payload_pull_request_user_login = 'mads379'
GROUP BY repository_url
ORDER BY last_pr DESC;
```

The results of the query is shown in the table below

|**repository\_url**                                          |**last\_pr**  |**language**|
|-----------------------------------------------------------------------------------------|
|https://github.com/diml/utop                                 |2014-11-05    |OCaml|
|https://github.com/bbatsov/projectile                        |2014-10-10    |Emacs Lisp|
|https://github.com/jlouis/dht_bt                             |2014-10-07    |Erlang|
|https://github.com/issuu/ocaml-redis                         |2014-08-26    |OCaml|
|https://github.com/ocaml-batteries-team/batteries-included   |2014-05-08    |OCaml|
|https://github.com/cabgfx/forge                              |2013-08-17    |PHP|
|https://github.com/scala-ide/scala-search                    |2013-08-02    |Scala|
|https://github.com/scala/scala                               |2013-01-26    |Scala|
|https://github.com/scala-ide/scala-ide                       |2013-01-04    |Scala|
|https://github.com/scala-ide/docs                            |2012-12-11    |JavaScript|
|https://github.com/textmate/textmate                         |2012-08-11    |C|
|https://github.com/avian/python-django-templates.tmbundle    |2012-08-06    |null|
|https://github.com/n8han/giter8                              |2012-08-05    |Scala|
|https://github.com/avian/textmate.tmbundle                   |2012-06-02    |Ruby|
|https://github.com/fileability/choc-support                  |2012-05-31    |JavaScript|
|https://github.com/leegould/GotoTab                          |2012-04-27    |Python|

The documentation for the BigQuery query language is
[here](https://cloud.google.com/bigquery/query-reference). I'm definitely going
to play around with this some more. Let me know if you come up with any other
fun queries.

**(Added 2015-02-05)** [Felipe Hoffa
(@felipehoffa)](https:www.twitter.com/felipehoffa) mentioned on Twitter
that the database layout for the archive was changed in 2015. You can
find more information about it in the [announcement
here](http://www.reddit.com/r/bigquery/comments/2s80y3/github_archive_changes_monthly_and_daily_tables/).
I personally prefer this format as the JSON from the Github Archive
documentation is stored directly in the tables which means I don't have
to guess the column names for the various nested fields.

```sql
SELECT
  repo_name,
  JSON_EXTRACT(payload, '$.pull_request.base.repo.language') as language,
  JSON_EXTRACT(payload, '$.pull_request.updated_at') as updated_at
FROM [githubarchive:month.201501]
WHERE
  type = 'PullRequestEvent' AND
  JSON_EXTRACT(payload, '$.pull_request.user.login') = 'mads379'
```
