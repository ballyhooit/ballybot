Hubot      = require 'hubot'
Fs         = require 'fs'
Path       = require 'path'
HTTP       = require 'http'
OptParse   = require 'optparse'
scriptInit = 0

Switches = [
  [ "-a", "--adapter ADAPTER", "The Adapter to use" ],
  [ "-d", "--disable-httpd",   "Disable the HTTP server" ],
  [ "-h", "--help",            "Display the help information" ],
  [ "-l", "--alias ALIAS",     "Enable replacing the robot's name with alias" ],
  [ "-n", "--name NAME",       "The name of the robot in chat" ],
  [ "-s", "--enable-slash",    "Enable replacing the robot's name with '/' (deprecated)" ],
  [ "-v", "--version",         "Displays the version of hubot installed" ]
]

Options =
  adapter: "socket.io"
  alias: false
  create: false
  enableHttpd: true
  name: "Ballybot"
  path: "."

Parser = new OptParse.OptionParser(Switches)
Parser.banner = "Usage hubot [options]"

Parser.on "adapter", (opt, value) ->
  Options.adapter = value

Parser.on "disable-httpd", (opt) ->
  Options.enableHttpd = false

Parser.on "help", (opt, value) ->
  console.log Parser.toString()
  process.exit 0

Parser.on "alias", (opt, value) ->
  Options.alias = value

Parser.on "name", (opt, value) ->
  Options.name = value

Parser.on "enable-slash", (opt) ->
  console.log "WARNING: -s and --enable-slash are deprecated please use -l or --alias '/'"
  Options.alias = '/'

Parser.on "version", (opt, value) ->
  Options.version = true

Parser.parse process.argv

unless process.platform is "win32"
  process.on 'SIGTERM', ->
    process.exit 0


adapterPath = Path.resolve __dirname, "..", "src", "adapters"
robot = Hubot.loadBot adapterPath, Options.adapter, Options.enableHttpd, Options.name

if Options.version
  console.log robot.version
  process.exit 0

robot.enableSlash = Options.enableSlash
robot.alias = Options.alias

loadScripts = ->
  scriptInit++
  scriptsPath = Path.resolve ".", "scripts"
  robot.load scriptsPath

  scriptsPath = Path.resolve "src", "scripts"
  robot.load scriptsPath

  scriptsFile = Path.resolve "hubot-scripts.json"
  
  Path.exists scriptsFile, (exists) =>
    if exists
      Fs.readFile scriptsFile, (err, data) ->
        scripts = JSON.parse data
        scriptsPath = Path.resolve "node_modules", "hubot-scripts", "src", "scripts"
        robot.loadHubotScripts scriptsPath, scripts

robot.adapter.on 'connected', loadScripts if scriptInit = 0

robot.run()

