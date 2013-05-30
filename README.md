git Served
==========

I wanted a simple way to access the files I managed in my various local git repositories the same way the "raw" links in GitHub allow me to.  These are repositires of code internal to me and/or my company and I couldn't just throw it up on public GitHub.  I also couldn't find anything that served HTTP requests out of a git repo like that in my various Google searching.  So I took a night and wrote one.

Hacking
-------

The current state of this code is stable and works for me, so I personally consider this "done".  There is however, a lot more that could be done to make it even cooler / better, and I would welcome any patches and pull requests.  I hoever won't have time for anything beyond basic tweaks and changes.

Here is my list of problems or additional features I thought of already but never bothered to implement:

* Prettier HTML output (e.g. templates) for repo/branch/directory lists
* Valid HTTP status codes when something goes wrong
  * 404 not found - non-existant URLs
  * 301 redirects - symlinks in the repo
* Authentication / Authorization (??)
* A way to access / map to repositories other then all in a single folder

Usage
-----

Just edit your config.yaml file with the path to your git repositories and fire it up in your favorite Ruby application / web server.

Here is a simplified rundown of how I deploy this:

```bash
mkdir -p /apps/git-served
cd /apps/git-served
git clone git://github.com/adregner/git-served.git .
echo ':git_root: "/var/path/to/git/repos"' > config.yaml
bundle install
bundle exec unicorn -l "<HOST:PORT|SOCKET>" -D config.ru
```
