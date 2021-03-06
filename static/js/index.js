// Internal stuff

import electron from 'electron'
import path from 'path'
import fs from 'fs'
import elm from '../../src/Main.elm'
import * as childProcess from 'child_process'

const { shell, remote } = electron
const { app, Menu, MenuItem } = remote


// A default configuration (actually, it is supported
// only a Terminal :) )
const defaultConfig = {
  terminal: "Terminal.app"
}


// Retreive the configuration object
function getConfigObject(config) {
  const homeDir = app.getPath('home')
  const qianDir = path.join(homeDir, '.qian')
  const qianFile = path.join(qianDir, 'profil.json')
  if (!fs.existsSync(qianDir)) {
    fs.mkdirSync(qianDir);
  }
  if (!fs.existsSync(qianFile)) {
    fs.writeFileSync(qianFile, JSON.stringify(config))
    return defaultConfig;
  }
  return JSON.parse(fs.readFileSync(qianFile))
}

// Rewrite the configuration file
function rewriteConfiguration(config) {
  const homeDir = app.getPath('home')
  const qianDir = path.join(homeDir, '.qian')
  const qianFile = path.join(qianDir, 'profil.json')
  if (!fs.existsSync(qianDir)) {
    fs.mkdirSync(qianDir);
  }
  fs.writeFileSync(qianFile, JSON.stringify(config))
}

const configObj = getConfigObject(defaultConfig)
const homePath = path.resolve(app.getPath('home'));

// Define the flag to be passed to the Elm Program
const flags = {
  current: homePath,
  config: configObj,
  home: homePath,
  root: '/'
}

// Initialize the Elm behaviour
const container = document.getElementById('app');
const elmApp = elm.Main.embed(container, flags);

// Application


function openInTerminal(app, dir) {
  childProcess.spawn('open', ['-a', app, dir])
}

// Ports to Elm Application

let watcher // the file Watcher
let currentTree = homePath;

const template =
  [
    {
      label: 'qian',
      submenu: [{role: 'about'}, {role: 'quit'}]
    },
    {
      label: 'Shortcuts',
      submenu: [
        {
          label: 'Pred',
          accelerator: 'CmdOrCtrl+<',
          click: function(item, focusedWindow) {
            if (focusedWindow) {
              elmApp.ports.historyNavigation.send(true)
            }
          }
        },
        {
          label: 'Next',
          accelerator: 'CmdOrCtrl+>',
          click: function(item, focusedWindow) {
            if (focusedWindow) {
              elmApp.ports.historyNavigation.send(false)
            }
          }
        },
        {
          label: 'Parent',
          accelerator: 'CmdOrCtrl+Shift+Space',
          click: function(item, focusedWindow) {
            if (focusedWindow) {
              elmApp.ports.jumpToParent.send(true)
            }
          }
        },
        {
          label: 'Open in finder',
          accelerator: 'CmdOrCtrl+Alt+enter',
          click: function(item, focusedWindow) {
            if (focusedWindow) {
              shell.showItemInFolder(currentTree)
            }
          }
        },
        {
          label: 'Open in Terminal',
          accelerator: 'CmdOrCtrl+enter',
          click: function(item, focusedWindow) {
            if (focusedWindow) {
              openInTerminal(configObj.terminal, currentTree)
            }
          }
        }
      ]
    }
  ];

const menu = Menu.buildFromTemplate(template)
Menu.setApplicationMenu(menu)

// Watch and get treeFile
elmApp.ports.getTree.subscribe((pwd) => {
  const dir = path.resolve(pwd)
  currentTree = dir;
  const tree = fs.readdirSync(dir).map((entry) => {
    const completePath = path.join(dir, entry)
    return {
      name: entry,
      path: completePath,
      hidden: entry[0] === '.' /* Maybe to be improve :/ */ ,
      directory: fs.lstatSync(completePath).isDirectory()
    }
  });
  if (watcher) {
    watcher.close()
  }
  watcher = fs.watch(dir, {
    encoding: 'buffer'
  }, (et, fn) => {
    elmApp.ports.treeMutation.send(true)
  })
  elmApp.ports.retreiveTree.send(tree)
});

// Open File with a default program
elmApp.ports.openFile.subscribe((pwd) => {
  const dir = path.resolve(pwd)
  shell.openItem(dir)
});

// Open folder in finder
elmApp.ports.openInFinder.subscribe((pwd) => {
  const dir = path.resolve(pwd)
  shell.showItemInFolder(dir)
});

elmApp.ports.openInTerminal.subscribe((input) => {
  const dir = path.resolve(input.path)
  openInTerminal(input.app, dir)
});

elmApp.ports.changeTerminal.subscribe((config) => {
  rewriteConfiguration(config)
});
