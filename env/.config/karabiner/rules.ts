import { writeFileSync } from "fs";
import type { KarabinerRules } from "./types";
import {
	appInWorkspace,
	createHyperSubLayers,
	switchToAppWorkspace,
} from "./utils";

const rules: KarabinerRules[] = [
	// Define the Hyper key itself
	{
		description: "Hyper Key (⌃⌥⇧⌘)",
		manipulators: [
			{
				description: "Caps Lock -> Hyper Key",
				from: {
					key_code: "caps_lock",
					modifiers: {
						optional: ["any"],
					},
				},
				to: [
					{
						set_variable: {
							name: "hyper",
							value: 1,
						},
					},
				],
				to_after_key_up: [
					{
						set_variable: {
							name: "hyper",
							value: 0,
						},
					},
				],
				to_if_alone: [
					{
						key_code: "caps_lock",
						hold_down_milliseconds: 200,
					},
					{
						key_code: "vk_none",
					},
				],
				type: "basic",
			},
			//      {
			//        type: "basic",
			//        description: "Disable CMD + Tab to force Hyper Key usage",
			//        from: {
			//          key_code: "tab",
			//          modifiers: {
			//            mandatory: ["left_command"],
			//          },
			//        },
			//        to: [
			//          {
			//            key_code: "tab",
			//          },
			//        ],
			//      },
		],
	},
	...createHyperSubLayers({
		// q = "Quick" applications
		q: {
			a: appInWorkspace("Arc", "company.thebrowser.Browser", "B"),
			s: appInWorkspace("Safari", "com.apple.Safari", "B"),
			i: appInWorkspace("IntelliJ IDEA", "com.jetbrains.intellij", "I"),
			w: appInWorkspace("WhatsApp", "net.whatsapp.WhatsApp", "W"),
			o: appInWorkspace("Obsidian", "md.obsidian", "O"),
			d: appInWorkspace("Dash", "com.kapeli.dashdoc", "D"),
			p: appInWorkspace("Spotify", "com.spotify.client", "M"),
			n: appInWorkspace("Notion", "notion.id", "N"),
			c: appInWorkspace("Calendar", "com.apple.iCal", "C"),
			y: appInWorkspace("System Settings", "com.apple.systempreferences", "Y"),
			g: appInWorkspace("Ghostty", "com.mitchellh.ghostty", "T"),
			t: appInWorkspace("Terminal", "com.apple.Terminal", "T"),
			f: appInWorkspace("Finder", "com.apple.finder", "E"),
			z: appInWorkspace("zoom.us", "us.zoom.xos", "Z"),
		},

		// e = "spacE" workspaces
		e: {
			1: {
				description: "Workspace 1 (Home)",
				to: [{ shell_command: "/opt/homebrew/bin/aerospace workspace 1" }],
			},
			2: {
				description: "Workspace 2",
				to: [{ shell_command: "/opt/homebrew/bin/aerospace workspace 2" }],
			},
			3: {
				description: "Workspace 3",
				to: [{ shell_command: "/opt/homebrew/bin/aerospace workspace 3" }],
			},
			4: {
				description: "Workspace 4",
				to: [{ shell_command: "/opt/homebrew/bin/aerospace workspace 4" }],
			},
			5: {
				description: "Workspace 5",
				to: [{ shell_command: "/opt/homebrew/bin/aerospace workspace 5" }],
			},
			6: {
				description: "Workspace 6",
				to: [{ shell_command: "/opt/homebrew/bin/aerospace workspace 6" }],
			},
			7: {
				description: "Workspace 7",
				to: [{ shell_command: "/opt/homebrew/bin/aerospace workspace 7" }],
			},
			8: {
				description: "Workspace 8",
				to: [{ shell_command: "/opt/homebrew/bin/aerospace workspace 8" }],
			},
			9: {
				description: "Workspace 9",
				to: [{ shell_command: "/opt/homebrew/bin/aerospace workspace 9" }],
			},
			b: switchToAppWorkspace("Arc", "B"),
			c: switchToAppWorkspace("Calendar", "C"),
			d: switchToAppWorkspace("Dash", "D"),
			e: switchToAppWorkspace("Finder", "E"),
			i: switchToAppWorkspace("IntelliJ IDEA", "I"),
			m: switchToAppWorkspace("Spotify", "M"),
			n: switchToAppWorkspace("Notion", "N"),
			o: switchToAppWorkspace("Obsidian", "O"),
			t: switchToAppWorkspace("Ghostty", "T"),
			w: switchToAppWorkspace("WhatsApp", "W"),
			y: switchToAppWorkspace("System Settings", "Y"),
			z: switchToAppWorkspace("zoom.us", "Z"),
			p: {
				description: "Workspace Back and Forth",
				to: [
					{
						shell_command:
							"/opt/homebrew/bin/aerospace workspace-back-and-forth",
					},
				],
			},
		},

		// w = "Window"

		w: {
			0: {
				description: "AeroSpace Sweep All Apps to Workspaces",
				to: [
					{
						shell_command:
							"/Users/tavongamatikiti/.config/aerospace/sweep-all.sh",
					},
				],
			},
			semicolon: {
				description: "Window: Hide",
				to: [
					{
						key_code: "h",
						modifiers: ["right_command"],
					},
				],
			},
			h: {
				description: "AeroSpace Focus Left",
				to: [{ shell_command: "/opt/homebrew/bin/aerospace focus left" }],
			},
			j: {
				description: "AeroSpace Focus Down",
				to: [{ shell_command: "/opt/homebrew/bin/aerospace focus down" }],
			},
			k: {
				description: "AeroSpace Focus Up",
				to: [{ shell_command: "/opt/homebrew/bin/aerospace focus up" }],
			},
			l: {
				description: "AeroSpace Focus Right",
				to: [{ shell_command: "/opt/homebrew/bin/aerospace focus right" }],
			},
			s: {
				description: "AeroSpace Split Horizontal + Balance",
				to: [
					{
						shell_command:
							"/opt/homebrew/bin/aerospace macos-native-fullscreen off; /opt/homebrew/bin/aerospace layout tiling; /opt/homebrew/bin/aerospace layout horizontal; /opt/homebrew/bin/aerospace balance-sizes",
					},
				],
			},
			v: {
				description: "AeroSpace Split Vertical + Balance",
				to: [
					{
						shell_command:
							"/opt/homebrew/bin/aerospace macos-native-fullscreen off; /opt/homebrew/bin/aerospace layout tiling; /opt/homebrew/bin/aerospace layout vertical; /opt/homebrew/bin/aerospace balance-sizes",
					},
				],
			},
			f: {
				description: "AeroSpace Toggle macOS Fullscreen",
				to: [
					{
						shell_command: "/opt/homebrew/bin/aerospace macos-native-fullscreen",
					},
				],
			},
			r: {
				description: "AeroSpace Balance Sizes",
				to: [{ shell_command: "/opt/homebrew/bin/aerospace balance-sizes" }],
			},
			hyphen: {
				description: "AeroSpace Resize Smaller",
				to: [{ shell_command: "/opt/homebrew/bin/aerospace resize smart -50" }],
			},
			equal_sign: {
				description: "AeroSpace Resize Larger",
				to: [{ shell_command: "/opt/homebrew/bin/aerospace resize smart +50" }],
			},
			comma: {
				description: "AeroSpace Resize Smaller",
				to: [{ shell_command: "/opt/homebrew/bin/aerospace resize smart -50" }],
			},
			period: {
				description: "AeroSpace Resize Larger",
				to: [{ shell_command: "/opt/homebrew/bin/aerospace resize smart +50" }],
			},
			y: {
				description: "AeroSpace Previous Workspace",
				to: [
					{
						shell_command:
							"/opt/homebrew/bin/aerospace workspace prev --no-stdin",
					},
				],
			},
			o: {
				description: "AeroSpace Next Workspace",
				to: [
					{
						shell_command:
							"/opt/homebrew/bin/aerospace workspace next --no-stdin",
					},
				],
			},
			p: {
				description: "AeroSpace Workspace Back and Forth",
				to: [
					{
						shell_command:
							"/opt/homebrew/bin/aerospace workspace-back-and-forth",
					},
				],
			},
			u: {
				description: "Window: Previous Tab",
				to: [
					{
						key_code: "tab",
						modifiers: ["right_control", "right_shift"],
					},
				],
			},
			i: {
				description: "Window: Next Tab",
				to: [
					{
						key_code: "tab",
						modifiers: ["right_control"],
					},
				],
			},
			n: {
				description: "Window: Next Window",
				to: [
					{
						key_code: "grave_accent_and_tilde",
						modifiers: ["right_command"],
					},
				],
			},
			b: {
				description: "Window: Back",
				to: [
					{
						key_code: "open_bracket",
						modifiers: ["right_command"],
					},
				],
			},
			// Note: No literal connection. Both f and n are already taken.
			m: {
				description: "Window: Forward",
				to: [
					{
						key_code: "close_bracket",
						modifiers: ["right_command"],
					},
				],
			},
		},

		// s = "System"
		s: {
			u: {
				to: [
					{
						key_code: "volume_increment",
					},
				],
			},
			j: {
				to: [
					{
						key_code: "volume_decrement",
					},
				],
			},
			i: {
				to: [
					{
						key_code: "display_brightness_increment",
					},
				],
			},
			k: {
				to: [
					{
						key_code: "display_brightness_decrement",
					},
				],
			},
			l: {
				to: [
					{
						key_code: "q",
						modifiers: ["right_control", "right_command"],
					},
				],
			},
			p: {
				to: [
					{
						key_code: "play_or_pause",
					},
				],
			},
			semicolon: {
				to: [
					{
						key_code: "fastforward",
					},
				],
			},
			// 'v'oice
			v: {
				to: [
					{
						key_code: "spacebar",
						modifiers: ["left_option"],
					},
				],
			},
		},

		// v = "moVe" which isn't "m" because we want it to be on the left hand
		// so that hjkl work like they do in vim
		v: {
			h: {
				to: [{ key_code: "left_arrow" }],
			},
			j: {
				to: [{ key_code: "down_arrow" }],
			},
			k: {
				to: [{ key_code: "up_arrow" }],
			},
			l: {
				to: [{ key_code: "right_arrow" }],
			},
			// Magicmove via homerow.app
			m: {
				to: [{ key_code: "f", modifiers: ["right_control"] }],
				// TODO: Trigger Vim Easymotion when VSCode is focused
			},
			// Scroll mode via homerow.app
			s: {
				to: [{ key_code: "j", modifiers: ["right_control"] }],
			},
			d: {
				to: [{ key_code: "d", modifiers: ["right_shift", "right_command"] }],
			},
			u: {
				to: [{ key_code: "page_down" }],
			},
			i: {
				to: [{ key_code: "page_up" }],
			},
		},

		// c = Musi*c* which isn't "m" because we want it to be on the left hand
		c: {
			p: {
				to: [{ key_code: "play_or_pause" }],
			},
			n: {
				to: [{ key_code: "fastforward" }],
			},
			b: {
				to: [{ key_code: "rewind" }],
			},
		},
	}),
];

writeFileSync(
	"karabiner.json",
	JSON.stringify(
		{
			global: {
				show_in_menu_bar: false,
			},
			profiles: [
				{
					name: "Default",
					complex_modifications: {
						rules,
					},
				},
			],
		},
		null,
		2,
	),
);
