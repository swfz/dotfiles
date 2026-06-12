-- plugins/tmux.lua
return {
  -- vimux: tmux pane runner
  -- lazy=false にして VimuxRunCommand 等が keymaps から即時使えるようにする
  {
    "preservim/vimux",
    lazy = false,
  },
}
