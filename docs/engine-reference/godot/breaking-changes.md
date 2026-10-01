# Godot — Breaking Changes

Last verified: 2026-10-01

Changes between Godot versions, focused on post-LLM-cutoff changes (4.4+).

## 4.6 → 4.7 (Jun 2026 — POST-CUTOFF, HIGH RISK)

Source: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html
(fetched 2026-10-01). Networking changes are NOT SOURCEABLE — the 4.7 release
notes and migration guide do not cover the networking subsystem at all; do not
assume no changes occurred there, especially relevant given this project's
planned co-op multiplayer.

| Subsystem | Change | Details |
|-----------|--------|---------|
| Core | `Object.is_class()` parameter type change | `class` parameter changes from `String` to `StringName` |
| GUI | `RichTextLabel.ImageUpdateMask.UPDATE_WIDTH_IN_PERCENT` renamed | Renamed to `UPDATE_WIDTH_UNIT` (GDScript-incompatible) |
| GUI | `RichTextLabel.add_image()` / `update_image()` signature change | Width/height change from `int` to `float`; `width_in_percent`/`height_in_percent` renamed to `width_unit`/`height_unit`, type becomes `ImageUnit` |
| GUI | `Control.accessibility_live` property type change | Type changes from `DisplayServer.AccessibilityLiveMode` to `AccessibilityServer.AccessibilityLiveMode` (C# incompatible) |
| Rendering | `ImageTexture.get_format()` / `PortableCompressedTexture2D.get_format()` moved | Moved to base `Texture2D` |
| Rendering | `RenderingServer.particles_request_process_time()` param rename | `time` renamed to `process_time`, adds `process_time_residual` (C# source incompatible) |
| Physics | `PhysicsServer2D.body_set_shape_as_one_way_collision()` | Adds optional `direction` parameter |
| Physics | `PhysicsServer2DExtension._body_set_shape_as_one_way_collision()` | Adds **required** `direction` parameter (incompatible override) |
| Audio | `AudioEffectSpectrumAnalyzer.tap_back_pos` | Property removed |
| Animation | `Animation.length` property metadata | Type changes `float` → `double` (C# incompatible) |
| Editor | `EditorSceneFormatImporter` import constants | Moved into `ImportFlags` enum (source incompatible) |

### Behavior changes (no signature change, output differs)

| Subsystem | Change |
|-----------|--------|
| Rendering | `LinearToSRGB` visual shader no longer clamps to `[0.0, 1.0]` on Mobile/Forward+ |
| Rendering | `CanvasItem` line drawing no longer adds antialiasing feather automatically — adjust thickness manually |
| Physics | Default `AudioStreamPlayer.area_mask` changes from `1` to `0` (disabled) |
| Physics | Jolt `WorldBoundaryShape3D` plane distance sign interpretation reverses |
| Physics | Jolt `SoftBody3D` mass now defaults to 1 kg (was 0); linear stiffness application adjusted |
| Physics | Jolt `Area3D` now reports overlaps with `SoftBody3D` |
| Input | Mouse/keyboard device IDs change from `0` to `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD` |
| GDScript | Setting a packed-array element no longer calls the setter for the whole packed-array property |
| GDScript | Methods overriding a typed-return method now inherit that return type — an implicit return may now need an explicit one |

### Changed defaults — relevant to this project (2D, PC)

| Setting | Old | New |
|---------|-----|-----|
| New-project default stretch mode (Display → Window) | `disabled` | `canvas_items` |
| New-project default stretch aspect | `keep` | `expand` |
| `ResourceImporterDynamicFont.hinting` | `1` | `3` |
| `LookAtModifier3D.relative` | `true` | `false` (3D only, not used by this project's current 2D scope) |

**Action for this project**: the stretch-mode default change affects any new
scene — confirm `project.godot`'s `[display]` settings explicitly once a
viewport/resolution strategy is chosen, rather than relying on the new-project
default silently applying.

## 4.5 → 4.6 (Jan 2026 — POST-CUTOFF, HIGH RISK)

| Subsystem | Change | Details |
|-----------|--------|---------|
| Physics | Jolt is now the DEFAULT 3D physics engine | New projects use Jolt automatically. Existing projects keep their setting. Some HingeJoint3D properties (like `damp`) only work with GodotPhysics. |
| Rendering | Glow processes BEFORE tonemapping | Was after tonemapping. Scenes with glow will look different. Adjust intensity/blend in WorldEnvironment. |
| Rendering | D3D12 default on Windows | Was Vulkan. For better driver compatibility. |
| Rendering | AgX tonemapper new controls | White point and contrast parameters added. |
| Core | Quaternion initializes to identity | Was zero. Unlikely to affect most code but technically breaking. |
| UI | Dual-focus system | Mouse/touch focus now separate from keyboard/gamepad focus. Visual feedback differs by input method. |
| Animation | IK system fully restored | CCDIK, FABRIK, Jacobian IK, Spline IK, TwoBoneIK via SkeletonModifier3D nodes. |
| Editor | New "Modern" theme default | Grayscale replaces blue-tint. Restore: Editor Settings → Interface → Theme → Style: Classic |
| Editor | "Select Mode" keybind changed | New "Select Mode" (v key) prevents accidental transforms. Old mode renamed "Transform Mode" (q key). |
| 2D | TileMapLayer scene tile rotation | Scene tiles can now be rotated like atlas tiles. |
| Localization | CSV plural form support | No longer requires Gettext for plurals. Context columns added. |
| C# | Automatic string extraction | Translation strings auto-extracted from C# code. |
| Plugins | New EditorDock class | Specialized container for plugin docks with layout control. |

## 4.4 → 4.5 (Late 2025 — POST-CUTOFF, HIGH RISK)

| Subsystem | Change | Details |
|-----------|--------|---------|
| GDScript | Variadic arguments added | Functions can accept `...` arbitrary params — new language feature |
| GDScript | `@abstract` decorator | Abstract classes and methods now enforceable |
| GDScript | Script backtracing | Detailed call stacks available even in Release builds |
| Rendering | Stencil buffer support | New capability for advanced visual effects |
| Rendering | SMAA 1x antialiasing | New post-processing AA option |
| Rendering | Shader Baker | Pre-compiles shaders — reportedly 20x faster startup on some demos |
| Rendering | Bent normal maps, specular occlusion | New material features |
| Accessibility | Screen reader support | Control nodes work with accessibility tools via AccessKit |
| Editor | Live translation preview | Test GUI layouts in different languages in-editor |
| Physics | 3D interpolation rearchitected | Moved from RenderingServer to SceneTree. API unchanged but internals differ. |
| Animation | BoneConstraint3D | New: AimModifier3D, CopyTransformModifier3D, ConvertTransformModifier3D |
| Resources | `duplicate_deep()` added | New explicit method for deep duplication of nested resources |
| Navigation | Dedicated 2D navigation server | No longer a proxy to 3D navigation; smaller export for 2D games |
| UI | FoldableContainer node | New accordion-style container for collapsible UI sections |
| UI | Recursive Control behavior | Disable mouse/focus interactions across entire node hierarchies |
| Platform | visionOS export support | New platform target |
| Platform | SDL3 gamepad driver | Delegated gamepad handling to SDL library |
| Platform | Android 16KB page support | Required for Google Play targeting Android 15+ |

## 4.3 → 4.4 (Mid 2025 — NEAR CUTOFF, VERIFY)

| Subsystem | Change | Details |
|-----------|--------|---------|
| Core | `FileAccess.store_*` return `bool` | Was `void`. Methods: `store_8`, `store_16`, `store_32`, `store_64`, `store_buffer`, `store_csv_line`, `store_double`, `store_float`, `store_half`, `store_line`, `store_pascal_string`, `store_real`, `store_string`, `store_var` |
| Core | `OS.execute_with_pipe` | Added optional `blocking` parameter |
| Core | `RegEx.compile/create_from_string` | Added optional `show_error` parameter |
| Rendering | `RenderingDevice.draw_list_begin` | Many parameters removed; `breadcrumb` parameter added |
| Rendering | `Shader.set_default_texture_parameter()` / `get_default_texture_parameter()` | Parameter/return type changed from `Texture2D` to `Texture`; the shading language did not change |
| Particles | `.restart()` method | Added optional `keep_seed` parameter (CPU/GPU 2D/3D) |
| GUI | `RichTextLabel.push_meta` | Added optional `tooltip` parameter |
| GUI | `GraphEdit.connect_node` | Added optional `keep_alive` parameter |

## 4.2 → 4.3 (In Training Data — LOW RISK)

| Subsystem | Change | Details |
|-----------|--------|---------|
| Animation | `Skeleton3D.add_bone` returns `int32` | Was `void` |
| Animation | `bone_pose_updated` signal | Replaced by `skeleton_updated` |
| TileMap | `TileMapLayer` replaces `TileMap` | One node per layer instead of multi-layer single node |
| Navigation | `NavigationRegion2D` | Removed `avoidance_layers`, `constrain_avoidance` properties |
| Editor | `EditorSceneFormatImporterFBX` | Renamed to `EditorSceneFormatImporterFBX2GLTF` |
| Animation | AnimationMixer base class | AnimationPlayer and AnimationTree now extend AnimationMixer |
