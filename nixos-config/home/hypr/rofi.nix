# modules/hypr/rofi.nix
{ config, pkgs, ... }: let
  inherit (config.lib.formats.rasi) mkLiteral;
  l = mkLiteral;
in {
  programs.rofi = {
    enable   = true;
    package  = pkgs.rofi;
    font     = "Fira Code 10";
    terminal = "wezterm";
    extraConfig = {
      modi       = "window,drun,ssh,combi";
      combi-modi = "window,drun,ssh";
    };

    # きぷきぷ — Matcha Latte / Material 3
    theme = {
      "*" = {
        font             = "FiraCode Nerd Font Medium 11";
        primary          = l "#A4BC7C";
        on-primary       = l "#283418";
        matcha-soft      = l "rgba(164, 188, 124, 0.22)";
        surface          = l "rgba(40, 47, 33, 0.60)";
        surface-high     = l "rgba(64, 73, 53, 0.60)";
        on-surface       = l "#ECE4CC";
        on-surface-dim   = l "#C4CDA8";
        outline          = l "rgba(120, 134, 92, 0.45)";
        background-color = l "transparent";
        text-color       = l "#ECE4CC";
        transparent      = l "rgba(0,0,0,0)";
      };
      "window" = {
        location         = l "center";
        anchor           = l "center";
        transparency     = "real";
        padding          = l "0px";
        border           = l "0px";
        border-radius    = l "28px";
        background-color = l "@transparent";
        spacing          = 0;
        children         = l "[mainbox]";
        width            = l "860px";
      };
      "mainbox" = {
        spacing          = 0;
        children         = l "[ inputbar, listview ]";
        border-radius    = l "28px";
        background-color = l "@surface";
      };
      "inputbar" = {
        children         = l "[ prompt, entry ]";
        padding          = l "18px 22px";
        background-color = l "@surface-high";
        border-radius    = l "28px 28px 0px 0px";
        border           = l "0px";
        text-color       = l "@on-surface";
      };
      "prompt" = {
        margin           = l "0px 12px 0px 0px";
        text-color       = l "@primary";
      };
      "entry" = {
        font              = l "inherit";
        text-color        = l "@on-surface";
        placeholder       = "Search...";
        placeholder-color = l "@on-surface-dim";
      };
      "listview" = {
        padding          = l "8px";
        border-radius    = l "0px 0px 28px 28px";
        background-color = l "transparent";
        dynamic          = false;
        lines            = 8;
        scrollbar        = false;
        spacing          = l "2px";
      };
      "element" = {
        padding          = l "10px 16px";
        vertical-align   = l "0.5";
        border-radius    = l "14px";
        background-color = l "transparent";
        text-color       = l "@on-surface";
        spacing          = l "12px";
      };
      "element normal.normal" = {
        background-color = l "transparent";
        text-color       = l "@on-surface";
      };
      "element alternate.normal" = {
        background-color = l "transparent";
        text-color       = l "@on-surface";
      };
      "element normal.active" = {
        background-color = l "@matcha-soft";
        text-color       = l "@primary";
      };
      "element selected.normal" = {
        background-color = l "@primary";
        text-color       = l "@on-primary";
      };
      "element selected.active" = {
        background-color = l "@primary";
        text-color       = l "@on-primary";
      };
      "element-text" = {
        background-color = l "inherit";
        text-color       = l "inherit";
        vertical-align   = l "0.5";
      };
      "element-icon" = {
        background-color = l "inherit";
        size             = l "1.2em";
      };
      "message" = {
        padding          = l "10px 16px";
        background-color = l "transparent";
        text-color       = l "@on-surface-dim";
      };
    };
  };
}
