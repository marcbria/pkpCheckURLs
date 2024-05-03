# Motivation

One of the tasks that takes more time when you install or upgrade any PKP tool is setting the right mod_rewrite rules. Working in the "[dojo](https://github.com/marcbria/dojo)" project, I realized we need rock-solid set of rules able to deal with:

- Http and httpS.
- RESTful and explicit urls.
- With and without journal's context (aka. journalSlug).
- Installed on a domain, subdomain or folder.
- OxS 3.2 or older.
- Multi and single-tenant.

In past, to create my own set of rules I followed a trial&error process that could be exhausting and sometimes not realiable enough till editors test the tool in real world and a full workflow was completed.

This script includes a few set of urls to check your OxS and be sure the essential OxS endpoints are reachable. 
Although it's a faster way to check your site, further testing is always recommended as far as those list are not yet officialy validated by PKP.


# About the script

`pkpCheckUrls` a simple bashscript that uses `curl` to check sets of urls and reports it in a comprehensible way.

Syntax is as follows:

```
./pkpCheckUrl typeOfTest [listOfServer.csv]
```

As you see, the scripts takes two parameteres:
- Type of test: Existing options are "basic", "restful" and "noSlug".
- List of servers: (optional) To refer an external file with a list of the OxS you like to text.

So, if you wan a try, just clone this repo and call it as follows:

```
$ ./pkpCheckUrl basic
$ ./pkpCheckUrl basic servers.list
```

First parameter let you decide the list of urls you are going to test. 
The most important part of the script as those list of endpoints thought for different secnarios.
Notice this list of endpoints was created based on my experience and enriched with comments from 
PKP fellows feedback but right now they are far from been exhaustive and realiable. 
PRs are welcome to improve this list.

Hopefully this will motivate PKP to publish a list of endpoints (as they did for 3.4 API) so we can have a realiable way to automatically test all essential urls for any PKP tool. 

Second parameter, when it's specified refers a CSV file where each row includes `base_url`, `journalContext` and `base_url[index]` so it let you check multiple sites with a single call. You can check your `base_url` vars in your config.inc.php and the `journalContext` in your OJS, as the url slug you add to your journal.
Notice lines started with "#" will be ignored so you can use it to document each case.

An `server.list` is included as an example to let you adapt it to your needs.
If second parameter is not specified, the test will run against PKP's demo site.

The lists you can check right now are:

### Basic

The `basic` set of rules test essential OxS endpoints that **EVERY OJS MUST RESPONSE**.

The set includes urls to check:
- Http and httpS.
- Site's urls.
- Journal's context.
- API calls (old and 3.4 new ones)
- OAI calls.
- Admin page.

| Description                                                    | Sample URL                                             |
|:-------------------------------------------------------------- |:------------------------------------------------------ |
| HTTP is defined (explicit and hopefully redirected to HTTPS)   | http://$BASEURL/index.php                              |
| HTTP is defined for home (redirected to index.php with HTTPS)  | http://$BASEURL                                        |
| Main page (usually redirected)                                 | https://$BASEURL                                       |
| Main page destination (explicit)                               | https://$BASEURL/index.php                             |
| OJS site's index (explicit)                                    | https://$BASEURL/index.php/index                       |
| Example of journal's verbs (explicit)                          | https://$BASEURL/index.php/$JOURNAL/about              |
| Call including \$\$\$call\$\$\$ (explicit)'                    | https://$BASEURL/index.php/$JOURNAL/\$\$\$call\$\$\$/page/page/css?name=stylesheet" |
| Journal  OAI endpoint (explicit)                               | https://$BASEURL/index.php/$JOURNAL/oai                |
| Sitewide OAI endpoint (explicit)                               | https://$BASEURL/index.php/index/oai                   |
| Journal  API endpoint (explicit)                               | https://$BASEURL/index.php/$JOURNAL/api/v1/contexts/1  |
| Sitewide API endpoint for OJS 3.4 (explicit)                   | https://$BASEURL/index.php/_/api/v1/contexts/1         |
| Installation endpoint (explicit and redirected once installed) | https://$BASEURL/index.php/index/install/install       |
| Sitewide Admin's base pages (explicit)                         | https://${ADMINURL}/index.php/index/admin              |


## RESTful

RESTful urls (sometimes called "clean urls") are urls that don't include the "index.php" parameter and reflect resources and actions following the principles of REST architecture. This is the usual way of building urls in modern web applications.

The `restful` test is a secondary list to check once you pass the "basic" test and your site is set with `restful=On`.

This set includes all former urls without the "index.php" thught for sites:
- With RESTful
- Installed on a DOMain or subdomain
- With the journal's context (journalSlug)

| Sample URL                                     | Description                                                              |
|:---------------------------------------------- |:------------------------------------------------------------------------ |
| OJS site's index (RESTful)                     | https://$BASEURL/index                                                   |
| Example of journal's verbs (RESTful)           | https://$BASEURL/$JOURNAL/about                                          |
| Call including $$$call$$$ (RESTful)            | https://$BASEURL/$JOURNAL/\$\$\$call\$\$\$/page/page/css?name=stylesheet |
| Journal  OAI endpoint (RESTful)                | https://$BASEURL/$JOURNAL/oai                                            |
| Sitewide OAI endpoint (RESTful)                | https://$BASEURL/index/oai                                               |
| Journal  API endpoint (RESTful)                | https://$BASEURL/$JOURNAL/api/v1/contexts/1                              |
| Sitewide API new 3.4 endpoint (RESTful)        | https://$BASEURL/_/api/v1/contexts/1                                     |
| Installation endpoint (RESTful and redirected) | https://$BASEURL/index/install/install                                   |
| Sitewide Admin's base pages (RESTful)          | https://${ADMINURL}/index/admin                                          |


## NoSlug

The `noslug` list include all former RESTful urls but without expossing the journal's context (url journal's slug).

It make a lot of sense in single-tenant installations where you like your journal to answer in the root domain (ie: https://foojournal.org) instead in a secondary path.

| Description                                    | Sample URL                                                      |
|:---------------------------------------------- |:--------------------------------------------------------------- |
| Example of journal's verbs (RESTful & noSlug)  | https://$BASEURL/about                                          |
| Call including $$$call$$$ (RESTful & noSlug)   | https://$BASEURL/\$\$\$call\$\$\$/page/page/css?name=stylesheet |
| Journal  OAI endpoint (RESTful & noSlug)       | https://$BASEURL/oai                                            |
| Sitewide Admin's base pages (RESTful & noSlug) | https://${ADMINURL}/index/oai                                   |
| Sitewide OAI endpoint (RESTful & noSlug)       | https://$BASEURL/admin/index/oai                                |
| Journal  API endpoint (RESTful & noSlug)       | https://$BASEURL/api/v1/contexts/1                              |
| Sitewide Admin's base pages (RESTful & noSlug) | https://${ADMINURL}/index/admin                                 |



