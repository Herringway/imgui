// dear imgui, v1.84
// (widgets code)
module d_imgui.imgui_widgets;

/*

Index of this file:

// [SECTION] Forward Declarations
// [SECTION] Widgets: Text, etc.
// [SECTION] Widgets: Main (Button, Image, Checkbox, RadioButton, ProgressBar, Bullet, etc.)
// [SECTION] Widgets: Low-level Layout helpers (Spacing, Dummy, NewLine, Separator, etc.)
// [SECTION] Widgets: ComboBox
// [SECTION] Data Type and Data Formatting Helpers
// [SECTION] Widgets: DragScalar, DragFloat, DragInt, etc.
// [SECTION] Widgets: SliderScalar, SliderFloat, SliderInt, etc.
// [SECTION] Widgets: InputScalar, InputFloat, InputInt, etc.
// [SECTION] Widgets: InputText, InputTextMultiline
// [SECTION] Widgets: ColorEdit, ColorPicker, ColorButton, etc.
// [SECTION] Widgets: TreeNode, CollapsingHeader, etc.
// [SECTION] Widgets: Selectable
// [SECTION] Widgets: ListBox
// [SECTION] Widgets: PlotLines, PlotHistogram
// [SECTION] Widgets: Value helpers
// [SECTION] Widgets: MenuItem, BeginMenu, EndMenu, etc.
// [SECTION] Widgets: BeginTabBar, EndTabBar, etc.
// [SECTION] Widgets: BeginTabItem, EndTabItem, etc.
// [SECTION] Widgets: Columns, BeginColumns, EndColumns, etc.

*/

// #if defined(_MSC_VER) && !defined(_CRT_SECURE_NO_WARNINGS)
// #define _CRT_SECURE_NO_WARNINGS
// #endif

import d_imgui.imgui_h;
// #ifndef IMGUI_DISABLE

// #ifndef IMGUI_DEFINE_MATH_OPERATORS
// #define IMGUI_DEFINE_MATH_OPERATORS
// #endif
import d_imgui.imconfig;
import d_imgui.imgui;
import d_imgui.imgui_internal;
import d_imgui.imgui_draw;
import d_imgui.imstb_textedit;
import d_imgui.imgui_tables;

//import core.stdc.string : strlen, memcpy, memcmp, memmove, memset, strcmp;
import d_snprintf.vararg;

nothrow:
@nogc:

// System includes
/+
#include <ctype.h>      // toupper
#if defined(_MSC_VER) && _MSC_VER <= 1500 // MSVC 2008 or earlier
#include <stddef.h>     // intptr_t
#else
#include <stdint.h>     // intptr_t
#endif
+/
alias intptr_t = size_t;
alias uintptr_t = size_t;

//-------------------------------------------------------------------------
// Warnings
//-------------------------------------------------------------------------

// Visual Studio warnings
/+
#ifdef _MSC_VER
#pragma warning (disable: 4127)     // condition expression is constant
#pragma warning (disable: 4996)     // 'This function or variable may be unsafe': strcpy, strdup, sprintf, vsnprintf, sscanf, fopen
#if defined(_MSC_VER) && _MSC_VER >= 1922 // MSVC 2019 16.2 or later
#pragma warning (disable: 5054)     // operator '|': deprecated between enumerations of different types
#endif
#pragma warning (disable: 26451)    // [Static Analyzer] Arithmetic overflow : Using operator 'xxx' on a 4 byte value and then casting the result to a 8 byte value. Cast the value to the wider type before calling operator 'xxx' to avoid overflow(io.2).
#pragma warning (disable: 26812)    // [Static Analyzer] The enum type 'xxx' is unscoped. Prefer 'enum class' over 'enum' (Enum.3).
#endif
+/

// Clang/GCC warnings with -Weverything
/+
#if defined(__clang__)
#if __has_warning("-Wunknown-warning-option")
#pragma clang diagnostic ignored "-Wunknown-warning-option"         // warning: unknown warning group 'xxx'                      // not all warnings are known by all Clang versions and they tend to be rename-happy.. so ignoring warnings triggers new warnings on some configuration. Great!
#endif
#pragma clang diagnostic ignored "-Wunknown-pragmas"                // warning: unknown warning group 'xxx'
#pragma clang diagnostic ignored "-Wold-style-cast"                 // warning: use of old-style cast                            // yes, they are more terse.
#pragma clang diagnostic ignored "-Wfloat-equal"                    // warning: comparing floating point with == or != is unsafe // storing and comparing against same constants (typically 0.0f) is ok.
#pragma clang diagnostic ignored "-Wformat-nonliteral"              // warning: format string is not a string literal            // passing non-literal to vsnformat(). yes, user passing incorrect format strings can crash the code.
#pragma clang diagnostic ignored "-Wsign-conversion"                // warning: implicit conversion changes signedness
#pragma clang diagnostic ignored "-Wzero-as-null-pointer-constant"  // warning: zero as null pointer constant                    // some standard header variations use #define NULL 0
#pragma clang diagnostic ignored "-Wdouble-promotion"               // warning: implicit conversion from 'float' to 'double' when passing argument to function  // using printf() is a misery with this as C++ va_arg ellipsis changes float to double.
#pragma clang diagnostic ignored "-Wenum-enum-conversion"           // warning: bitwise operation between different enumeration types ('XXXFlags_' and 'XXXFlagsPrivate_')
#pragma clang diagnostic ignored "-Wdeprecated-enum-enum-conversion"// warning: bitwise operation between different enumeration types ('XXXFlags_' and 'XXXFlagsPrivate_') is deprecated
#pragma clang diagnostic ignored "-Wimplicit-int-float-conversion"  // warning: implicit conversion from 'xxx' to 'float' may lose precision
#elif defined(__GNUC__)
#pragma GCC diagnostic ignored "-Wpragmas"                          // warning: unknown option after '#pragma GCC diagnostic' kind
#pragma GCC diagnostic ignored "-Wformat-nonliteral"                // warning: format not a string literal, format string not checked
#pragma GCC diagnostic ignored "-Wclass-memaccess"                  // [__GNUC__ >= 8] warning: 'memset/memcpy' clearing/writing an object of type 'xxxx' with no trivial copy-assignment; use assignment or value-initialization instead
#endif
+/

//-------------------------------------------------------------------------
// Data
//-------------------------------------------------------------------------

// Widgets
__gshared const float          DRAGDROP_HOLD_TO_OPEN_TIMER = 0.70f;    // Time for drag-hold to activate items accepting the ImGuiButtonFlags_PressedOnDragDropHold button behavior.
__gshared const float          DRAG_MOUSE_THRESHOLD_FACTOR = 0.50f;    // Multiplier for the default value of io.MouseDragThreshold to make DragFloat/DragInt react faster to mouse drags.

// Those MIN/MAX values are not define because we need to point to them
__gshared const byte    IM_S8_MIN  = -128;
__gshared const byte    IM_S8_MAX  = 127;
__gshared const ubyte  IM_U8_MIN  = 0;
__gshared const ubyte  IM_U8_MAX  = 0xFF;
__gshared const short   IM_S16_MIN = -32768;
__gshared const short   IM_S16_MAX = 32767;
__gshared const ushort IM_U16_MIN = 0;
__gshared const ushort IM_U16_MAX = 0xFFFF;
__gshared const ImS32          IM_S32_MIN = INT_MIN;    // (-2147483647 - 1), (0x80000000);
__gshared const ImS32          IM_S32_MAX = INT_MAX;    // (2147483647), (0x7FFFFFFF)
__gshared const ImU32          IM_U32_MIN = 0;
__gshared const ImU32          IM_U32_MAX = UINT_MAX;   // (0xFFFFFFFF)
__gshared const ImS64          IM_S64_MIN = LLONG_MIN;  // (-9223372036854775807ll - 1ll);
__gshared const ImS64          IM_S64_MAX = LLONG_MAX;  // (9223372036854775807ll);
__gshared const ImU64          IM_U64_MIN = 0;
__gshared const ImU64          IM_U64_MAX = ULLONG_MAX; // (0xFFFFFFFFFFFFFFFFull);

//-------------------------------------------------------------------------
// [SECTION] Forward Declarations
//-------------------------------------------------------------------------

// For InputTextEx()
// static bool             InputTextFilterCharacter(uint* p_char, ImGuiInputTextFlags flags, ImGuiInputTextCallback callback, void* user_data, ImGuiInputSource input_source);
// static int              InputTextCalcTextLenAndLineCount(string text_begin, string* out_text_end);
// static ImVec2           InputTextCalcTextSizeW(const ImWchar* text_begin, const ImWchar* text_end, const ImWchar** remaining = NULL, ImVec2* out_offset = NULL, bool stop_on_new_line = false);

//-------------------------------------------------------------------------
// [SECTION] Widgets: Text, etc.
//-------------------------------------------------------------------------
// - TextEx() [Internal]
// - TextUnformatted()
// - Text()
// - TextV()
// - TextColored()
// - TextColoredV()
// - TextDisabled()
// - TextDisabledV()
// - TextWrapped()
// - TextWrappedV()
// - LabelText()
// - LabelTextV()
// - BulletText()
// - BulletTextV()
//-------------------------------------------------------------------------

void TextEx(string text, ImGuiTextFlags flags = ImGuiTextFlags.None)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return;

    ImGuiContext* g = GImGui;
    IM_ASSERT(text !is NULL);

    const ImVec2 text_pos = ImVec2(window.DC.CursorPos.x, window.DC.CursorPos.y + window.DC.CurrLineTextBaseOffset);
    const float wrap_pos_x = window.DC.TextWrapPos;
    const bool wrap_enabled = (wrap_pos_x >= 0.0f);
    if (text.length > 2000 && !wrap_enabled)
    {
        // Long text!
        // - From this point we will only compute the width of lines that are visible. Optimization only available when word-wrapping is disabled.
        // - We also don't vertically center the text within the line full height, which is unlikely to matter because we are likely the biggest and only item on the line.
        // - We use memchr(), pay attention that well optimized versions of those str/mem functions are much faster than a casually written loop.
        size_t line = 0;
        const float line_height = GetTextLineHeight();
        ImVec2 text_size = ImVec2(0, 0);

        // Lines to skip (can't skip when logging text)
        ImVec2 pos = text_pos;
        if (!g.LogEnabled)
        {
            int lines_skippable = cast(int)((window.ClipRect.Min.y - text_pos.y) / line_height);
            if (lines_skippable > 0)
            {
                int lines_skipped = 0;
                while (line < text.length && lines_skipped < lines_skippable)
                {
                    ptrdiff_t line_end = ImIndexOf(text, line, '\n');
                    if (line_end == -1)
                        line_end = text.length;
                    if ((flags & ImGuiTextFlags.NoWidthForLargeClippedText) == 0)
                        text_size.x = ImMax(text_size.x, CalcTextSize(text[line..line_end]).x);
                    line = line_end + 1;
                    lines_skipped++;
                }
                pos.y += lines_skipped * line_height;
            }
        }

        // Lines to render
        if (line < text.length)
        {
            ImRect line_rect = ImRect(pos, pos + ImVec2(FLT_MAX, line_height));
            while (line < text.length)
            {
                if (IsClippedEx(line_rect, 0, false))
                    break;

                ptrdiff_t line_end = ImIndexOf(text, line, '\n');
                if (line_end == -1)
                    line_end = text.length;
                text_size.x = ImMax(text_size.x, CalcTextSize(text[line..line_end]).x);
                RenderText(pos, text[line..line_end], false);
                line = line_end + 1;
                line_rect.Min.y += line_height;
                line_rect.Max.y += line_height;
                pos.y += line_height;
            }

            // Count remaining lines
            int lines_skipped = 0;
            while (line < text.length)
            {
                ptrdiff_t line_end = ImIndexOf(text, line, '\n');
                if (line_end == -1)
                    line_end = text.length;
                if ((flags & ImGuiTextFlags.NoWidthForLargeClippedText) == 0)
                    text_size.x = ImMax(text_size.x, CalcTextSize(text[line..line_end]).x);
                line = line_end + 1;
                lines_skipped++;
            }
            pos.y += lines_skipped * line_height;
        }
        text_size.y = (pos - text_pos).y;

        ImRect bb = ImRect(text_pos, text_pos + text_size);
        ItemSize(text_size, 0.0f);
        ItemAdd(bb, 0);
    }
    else
    {
        const float wrap_width = wrap_enabled ? CalcWrapWidthForPos(window.DC.CursorPos, wrap_pos_x) : 0.0f;
        const ImVec2 text_size = CalcTextSize(text, false, wrap_width);

        ImRect bb = ImRect(text_pos, text_pos + text_size);
        ItemSize(text_size, 0.0f);
        if (!ItemAdd(bb, 0))
            return;

        // Render (we don't hide text after ## in this end-user function)
        RenderTextWrapped(bb.Min, text, wrap_width);
    }
}

void TextUnformatted(string text)
{
    TextEx(text, ImGuiTextFlags.NoWidthForLargeClippedText);
}

void Text(A...)(string fmt, A a)
{
    mixin va_start!a;
    TextV(fmt, va_args);
    va_end(va_args);
}

void TextV(string fmt, va_list args)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return;

    ImGuiContext* g = GImGui;
    int text_end = ImFormatStringV(g.TempBuffer, fmt, args);
    TextEx(cast(string)g.TempBuffer[0..text_end], ImGuiTextFlags.NoWidthForLargeClippedText);
}

void TextColored(A...)(const ImVec4/*&*/ col, string fmt, A a)
{
    mixin va_start!a;
    TextColoredV(col, fmt, va_args);
    va_end(va_args);
}

void TextColoredV(const ImVec4/*&*/ col, string fmt, va_list args)
{
    PushStyleColor(ImGuiCol.Text, col);
    if (fmt == "%s")
        TextEx(va_arg!string(args), ImGuiTextFlags.NoWidthForLargeClippedText); // Skip formatting
    else
        TextV(fmt, args);
    PopStyleColor();
}

void TextDisabled(A...)(string fmt, A a)
{
    mixin va_start!a;
    TextDisabledV(fmt, va_args);
    va_end(va_args);
}

void TextDisabledV(string fmt, va_list args)
{
    ImGuiContext* g = GImGui;
    PushStyleColor(ImGuiCol.Text, g.Style.Colors[ImGuiCol.TextDisabled]);
    if (fmt == "%s")
        TextEx(va_arg!string(args), ImGuiTextFlags.NoWidthForLargeClippedText); // Skip formatting
    else
        TextV(fmt, args);
    PopStyleColor();
}

void TextWrapped(A...)(string fmt, A a)
{
    mixin va_start!a;
    TextWrappedV(fmt, va_args);
    va_end(va_args);
}

void TextWrappedV(string fmt, va_list args)
{
    ImGuiContext* g = GImGui;
    bool need_backup = (g.CurrentWindow.DC.TextWrapPos < 0.0f);  // Keep existing wrap position if one is already set
    if (need_backup)
        PushTextWrapPos(0.0f);
    if (fmt == "%s")
        TextEx(va_arg!string(args), ImGuiTextFlags.NoWidthForLargeClippedText); // Skip formatting
    else
        TextV(fmt, args);
    if (need_backup)
        PopTextWrapPos();
}

void LabelText(A...)(string label, string fmt, A a)
{
    mixin va_start!a;
    LabelTextV(label, fmt, va_args);
    va_end(va_args);
}

// Add a label+text combo aligned to other label+value widgets
void LabelTextV(string label, string fmt, va_list args)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return;

    ImGuiContext* g = GImGui;
    const ImGuiStyle* style = &g.Style;
    const float w = CalcItemWidth();

    int value_text_end = ImFormatStringV(g.TempBuffer, fmt, args);
    string value_text = cast(string)g.TempBuffer[0..value_text_end];
    const ImVec2 value_size = CalcTextSize(value_text, false);
    const ImVec2 label_size = CalcTextSize(label, true);

    const ImVec2 pos = window.DC.CursorPos;
    const ImRect value_bb = ImRect(pos, pos + ImVec2(w, value_size.y + style.FramePadding.y * 2));
    const ImRect total_bb = ImRect(pos, pos + ImVec2(w + (label_size.x > 0.0f ? style.ItemInnerSpacing.x + label_size.x : 0.0f), ImMax(value_size.y, label_size.y) + style.FramePadding.y * 2));
    ItemSize(total_bb, style.FramePadding.y);
    if (!ItemAdd(total_bb, 0))
        return;

    // Render
    RenderTextClipped(value_bb.Min + style.FramePadding, value_bb.Max, value_text, &value_size, ImVec2(0.0f, 0.0f));
    if (label_size.x > 0.0f)
        RenderText(ImVec2(value_bb.Max.x + style.ItemInnerSpacing.x, value_bb.Min.y + style.FramePadding.y), label);
}

void BulletText(A...)(string fmt, A a)
{
    mixin va_start!a;
    BulletTextV(fmt, va_args);
    va_end(va_args);
}

// Text with a little bullet aligned to the typical tree node.
void BulletTextV(string fmt, va_list args)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return;

    ImGuiContext* g = GImGui;
    const ImGuiStyle* style = &g.Style;

    int text_end = ImFormatStringV(g.TempBuffer, fmt, args);
    string text = cast(string)g.TempBuffer[0..text_end];
    const ImVec2 label_size = CalcTextSize(text, false);
    const ImVec2 total_size = ImVec2(g.FontSize + (label_size.x > 0.0f ? (label_size.x + style.FramePadding.x * 2) : 0.0f), label_size.y);  // Empty text doesn't add padding
    ImVec2 pos = window.DC.CursorPos;
    pos.y += window.DC.CurrLineTextBaseOffset;
    ItemSize(total_size, 0.0f);
    const ImRect bb = ImRect(pos, pos + total_size);
    if (!ItemAdd(bb, 0))
        return;

    // Render
    ImU32 text_col = GetColorU32(ImGuiCol.Text);
    RenderBullet(window.DrawList, bb.Min + ImVec2(style.FramePadding.x + g.FontSize * 0.5f, g.FontSize * 0.5f), text_col);
    RenderText(bb.Min + ImVec2(g.FontSize + style.FramePadding.x * 2, 0.0f), text, false);
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: Main
//-------------------------------------------------------------------------
// - ButtonBehavior() [Internal]
// - Button()
// - SmallButton()
// - InvisibleButton()
// - ArrowButton()
// - CloseButton() [Internal]
// - CollapseButton() [Internal]
// - GetWindowScrollbarID() [Internal]
// - GetWindowScrollbarRect() [Internal]
// - Scrollbar() [Internal]
// - ScrollbarEx() [Internal]
// - Image()
// - ImageButton()
// - Checkbox()
// - CheckboxFlagsT() [Internal]
// - CheckboxFlags()
// - RadioButton()
// - ProgressBar()
// - Bullet()
//-------------------------------------------------------------------------

// The ButtonBehavior() function is key to many interactions and used by many/most widgets.
// Because we handle so many cases (keyboard/gamepad navigation, drag and drop) and many specific behavior (via ImGuiButtonFlags_),
// this code is a little complex.
// By far the most common path is interacting with the Mouse using the default ImGuiButtonFlags_PressedOnClickRelease button behavior.
// See the series of events below and the corresponding state reported by dear imgui:
//------------------------------------------------------------------------------------------------------------------------------------------------
// with PressedOnClickRelease:             return-value  IsItemHovered()  IsItemActive()  IsItemActivated()  IsItemDeactivated()  IsItemClicked()
//   Frame N+0 (mouse is outside bb)        -             -                -               -                  -                    -
//   Frame N+1 (mouse moves inside bb)      -             true             -               -                  -                    -
//   Frame N+2 (mouse button is down)       -             true             true            true               -                    true
//   Frame N+3 (mouse button is down)       -             true             true            -                  -                    -
//   Frame N+4 (mouse moves outside bb)     -             -                true            -                  -                    -
//   Frame N+5 (mouse moves inside bb)      -             true             true            -                  -                    -
//   Frame N+6 (mouse button is released)   true          true             -               -                  true                 -
//   Frame N+7 (mouse button is released)   -             true             -               -                  -                    -
//   Frame N+8 (mouse moves outside bb)     -             -                -               -                  -                    -
//------------------------------------------------------------------------------------------------------------------------------------------------
// with PressedOnClick:                    return-value  IsItemHovered()  IsItemActive()  IsItemActivated()  IsItemDeactivated()  IsItemClicked()
//   Frame N+2 (mouse button is down)       true          true             true            true               -                    true
//   Frame N+3 (mouse button is down)       -             true             true            -                  -                    -
//   Frame N+6 (mouse button is released)   -             true             -               -                  true                 -
//   Frame N+7 (mouse button is released)   -             true             -               -                  -                    -
//------------------------------------------------------------------------------------------------------------------------------------------------
// with PressedOnRelease:                  return-value  IsItemHovered()  IsItemActive()  IsItemActivated()  IsItemDeactivated()  IsItemClicked()
//   Frame N+2 (mouse button is down)       -             true             -               -                  -                    true
//   Frame N+3 (mouse button is down)       -             true             -               -                  -                    -
//   Frame N+6 (mouse button is released)   true          true             -               -                  -                    -
//   Frame N+7 (mouse button is released)   -             true             -               -                  -                    -
//------------------------------------------------------------------------------------------------------------------------------------------------
// with PressedOnDoubleClick:              return-value  IsItemHovered()  IsItemActive()  IsItemActivated()  IsItemDeactivated()  IsItemClicked()
//   Frame N+0 (mouse button is down)       -             true             -               -                  -                    true
//   Frame N+1 (mouse button is down)       -             true             -               -                  -                    -
//   Frame N+2 (mouse button is released)   -             true             -               -                  -                    -
//   Frame N+3 (mouse button is released)   -             true             -               -                  -                    -
//   Frame N+4 (mouse button is down)       true          true             true            true               -                    true
//   Frame N+5 (mouse button is down)       -             true             true            -                  -                    -
//   Frame N+6 (mouse button is released)   -             true             -               -                  true                 -
//   Frame N+7 (mouse button is released)   -             true             -               -                  -                    -
//------------------------------------------------------------------------------------------------------------------------------------------------
// Note that some combinations are supported,
// - PressedOnDragDropHold can generally be associated with any flag.
// - PressedOnDoubleClick can be associated by PressedOnClickRelease/PressedOnRelease, in which case the second release event won't be reported.
//------------------------------------------------------------------------------------------------------------------------------------------------
// The behavior of the return-value changes when ImGuiButtonFlags_Repeat is set:
//                                         Repeat+                  Repeat+           Repeat+             Repeat+
//                                         PressedOnClickRelease    PressedOnClick    PressedOnRelease    PressedOnDoubleClick
//-------------------------------------------------------------------------------------------------------------------------------------------------
//   Frame N+0 (mouse button is down)       -                        true              -                   true
//   ...                                    -                        -                 -                   -
//   Frame N + RepeatDelay                  true                     true              -                   true
//   ...                                    -                        -                 -                   -
//   Frame N + RepeatDelay + RepeatRate*N   true                     true              -                   true
//-------------------------------------------------------------------------------------------------------------------------------------------------

bool ButtonBehavior(const ImRect/*&*/ bb, ImGuiID id, bool* out_hovered, bool* out_held, ImGuiButtonFlags flags = ImGuiButtonFlags.None)
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = GetCurrentWindow();

    // Default only reacts to left mouse button
    if ((flags & ImGuiButtonFlags.MouseButtonMask_) == 0)
        flags |= ImGuiButtonFlags.MouseButtonDefault_;

    // Default behavior requires click + release inside bounding box
    if ((flags & ImGuiButtonFlags.PressedOnMask_) == 0)
        flags |= ImGuiButtonFlags.PressedOnDefault_;

    ImGuiWindow* backup_hovered_window = g.HoveredWindow;
    const bool flatten_hovered_children = (flags & ImGuiButtonFlags.FlattenChildren) && g.HoveredWindow && g.HoveredWindow.RootWindow == window;
    if (flatten_hovered_children)
        g.HoveredWindow = window;

version (IMGUI_ENABLE_TEST_ENGINE) {
    if (id != 0 && g.LastItemData.ID != id)
        IMGUI_TEST_ENGINE_ITEM_ADD(&bb, id);
}

    bool pressed = false;
    bool hovered = ItemHoverable(bb, id);

    // Drag source doesn't report as hovered
    if (hovered && g.DragDropActive && g.DragDropPayload.SourceId == id && !(g.DragDropSourceFlags & ImGuiDragDropFlags.SourceNoDisableHover))
        hovered = false;

    // Special mode for Drag and Drop where holding button pressed for a long time while dragging another item triggers the button
    if (g.DragDropActive && (flags & ImGuiButtonFlags.PressedOnDragDropHold) && !(g.DragDropSourceFlags & ImGuiDragDropFlags.SourceNoHoldToOpenOthers))
        if (IsItemHovered(ImGuiHoveredFlags.AllowWhenBlockedByActiveItem))
        {
            hovered = true;
            SetHoveredID(id);
            if (g.HoveredIdTimer - g.IO.DeltaTime <= DRAGDROP_HOLD_TO_OPEN_TIMER && g.HoveredIdTimer >= DRAGDROP_HOLD_TO_OPEN_TIMER)
            {
                pressed = true;
                g.DragDropHoldJustPressedId = id;
                FocusWindow(window);
            }
        }

    if (flatten_hovered_children)
        g.HoveredWindow = backup_hovered_window;

    // AllowOverlap mode (rarely used) requires previous frame HoveredId to be null or to match. This allows using patterns where a later submitted widget overlaps a previous one.
    if (hovered && (flags & ImGuiButtonFlags.AllowItemOverlap) && (g.HoveredIdPreviousFrame != id && g.HoveredIdPreviousFrame != 0))
        hovered = false;

    // Mouse handling
    if (hovered)
    {
        if (!(flags & ImGuiButtonFlags.NoKeyModifiers) || (!g.IO.KeyCtrl && !g.IO.KeyShift && !g.IO.KeyAlt))
        {
            // Poll buttons
            ImGuiMouseButton mouse_button_clicked = ImGuiMouseButton.None;
            ImGuiMouseButton mouse_button_released = ImGuiMouseButton.None;
            if ((flags & ImGuiButtonFlags.MouseButtonLeft) && g.IO.MouseClicked[0])         { mouse_button_clicked = ImGuiMouseButton.Left; }
            else if ((flags & ImGuiButtonFlags.MouseButtonRight) && g.IO.MouseClicked[1])   { mouse_button_clicked = ImGuiMouseButton.Right; }
            else if ((flags & ImGuiButtonFlags.MouseButtonMiddle) && g.IO.MouseClicked[2])  { mouse_button_clicked = ImGuiMouseButton.Middle; }
            if ((flags & ImGuiButtonFlags.MouseButtonLeft) && g.IO.MouseReleased[0])        { mouse_button_released = ImGuiMouseButton.Left; }
            else if ((flags & ImGuiButtonFlags.MouseButtonRight) && g.IO.MouseReleased[1])  { mouse_button_released = ImGuiMouseButton.Right; }
            else if ((flags & ImGuiButtonFlags.MouseButtonMiddle) && g.IO.MouseReleased[2]) { mouse_button_released = ImGuiMouseButton.Middle; }

            if (mouse_button_clicked != -1 && g.ActiveId != id)
            {
                if (flags & (ImGuiButtonFlags.PressedOnClickRelease | ImGuiButtonFlags.PressedOnClickReleaseAnywhere))
                {
                    SetActiveID(id, window);
                    g.ActiveIdMouseButton = mouse_button_clicked;
                    if (!(flags & ImGuiButtonFlags.NoNavFocus))
                        SetFocusID(id, window);
                    FocusWindow(window);
                }
                if ((flags & ImGuiButtonFlags.PressedOnClick) || ((flags & ImGuiButtonFlags.PressedOnDoubleClick) && g.IO.MouseDoubleClicked[mouse_button_clicked]))
                {
                    pressed = true;
                    if (flags & ImGuiButtonFlags.NoHoldingActiveId)
                        ClearActiveID();
                    else
                        SetActiveID(id, window); // Hold on ID
                    g.ActiveIdMouseButton = mouse_button_clicked;
                    FocusWindow(window);
                }
            }
            if ((flags & ImGuiButtonFlags.PressedOnRelease) && mouse_button_released != -1)
            {
                // Repeat mode trumps on release behavior
                const bool has_repeated_at_least_once = (flags & ImGuiButtonFlags.Repeat) && g.IO.MouseDownDurationPrev[mouse_button_released] >= g.IO.KeyRepeatDelay;
                if (!has_repeated_at_least_once)
                    pressed = true;
                ClearActiveID();
            }

            // 'Repeat' mode acts when held regardless of _PressedOn flags (see table above).
            // Relies on repeat logic of IsMouseClicked() but we may as well do it ourselves if we end up exposing finer RepeatDelay/RepeatRate settings.
            if (g.ActiveId == id && (flags & ImGuiButtonFlags.Repeat))
                if (g.IO.MouseDownDuration[g.ActiveIdMouseButton] > 0.0f && IsMouseClicked(g.ActiveIdMouseButton, true))
                    pressed = true;
        }

        if (pressed)
            g.NavDisableHighlight = true;
    }

    // Gamepad/Keyboard navigation
    // We report navigated item as hovered but we don't set g.HoveredId to not interfere with mouse.
    if (g.NavId == id && !g.NavDisableHighlight && g.NavDisableMouseHover && (g.ActiveId == 0 || g.ActiveId == id || g.ActiveId == window.MoveId))
        if (!(flags & ImGuiButtonFlags.NoHoveredOnFocus))
            hovered = true;
    if (g.NavActivateDownId == id)
    {
        bool nav_activated_by_code = (g.NavActivateId == id);
        bool nav_activated_by_inputs = IsNavInputTest(ImGuiNavInput.Activate, (flags & ImGuiButtonFlags.Repeat) ? ImGuiInputReadMode.Repeat : ImGuiInputReadMode.Pressed);
        if (nav_activated_by_code || nav_activated_by_inputs)
            pressed = true;
        if (nav_activated_by_code || nav_activated_by_inputs || g.ActiveId == id)
        {
            // Set active id so it can be queried by user via IsItemActive(), equivalent of holding the mouse button.
            g.NavActivateId = id; // This is so SetActiveId assign a Nav source
            SetActiveID(id, window);
            if ((nav_activated_by_code || nav_activated_by_inputs) && !(flags & ImGuiButtonFlags.NoNavFocus))
                SetFocusID(id, window);
        }
    }

    // Process while held
    bool held = false;
    if (g.ActiveId == id)
    {
        if (g.ActiveIdSource == ImGuiInputSource.Mouse)
        {
            if (g.ActiveIdIsJustActivated)
                g.ActiveIdClickOffset = g.IO.MousePos - bb.Min;

            const int mouse_button = g.ActiveIdMouseButton;
            IM_ASSERT(mouse_button >= 0 && mouse_button < ImGuiMouseButton.COUNT);
            if (g.IO.MouseDown[mouse_button])
            {
                held = true;
            }
            else
            {
                bool release_in = hovered && (flags & ImGuiButtonFlags.PressedOnClickRelease) != 0;
                bool release_anywhere = (flags & ImGuiButtonFlags.PressedOnClickReleaseAnywhere) != 0;
                if ((release_in || release_anywhere) && !g.DragDropActive)
                {
                    // Report as pressed when releasing the mouse (this is the most common path)
                    bool is_double_click_release = (flags & ImGuiButtonFlags.PressedOnDoubleClick) && g.IO.MouseDownWasDoubleClick[mouse_button];
                    bool is_repeating_already = (flags & ImGuiButtonFlags.Repeat) && g.IO.MouseDownDurationPrev[mouse_button] >= g.IO.KeyRepeatDelay; // Repeat mode trumps <on release>
                    if (!is_double_click_release && !is_repeating_already)
                        pressed = true;
                }
                ClearActiveID();
            }
            if (!(flags & ImGuiButtonFlags.NoNavFocus))
                g.NavDisableHighlight = true;
        }
        else if (g.ActiveIdSource == ImGuiInputSource.Nav)
        {
            // When activated using Nav, we hold on the ActiveID until activation button is released
            if (g.NavActivateDownId != id)
                ClearActiveID();
        }
        if (pressed)
            g.ActiveIdHasBeenPressedBefore = true;
    }

    if (out_hovered) *out_hovered = hovered;
    if (out_held) *out_held = held;

    return pressed;
}

bool ButtonEx(string label, const ImVec2/*&*/ size_arg = ImVec2(0, 0), ImGuiButtonFlags flags = ImGuiButtonFlags.None)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    ImGuiContext* g = GImGui;
    const ImGuiStyle* style = &g.Style;
    const ImGuiID id = window.GetID(label);
    const ImVec2 label_size = CalcTextSize(label, true);

    ImVec2 pos = window.DC.CursorPos;
    if ((flags & ImGuiButtonFlags.AlignTextBaseLine) && style.FramePadding.y < window.DC.CurrLineTextBaseOffset) // Try to vertically align buttons that are smaller/have no padding so that text baseline matches (bit hacky, since it shouldn't be a flag)
        pos.y += window.DC.CurrLineTextBaseOffset - style.FramePadding.y;
    ImVec2 size = CalcItemSize(size_arg, label_size.x + style.FramePadding.x * 2.0f, label_size.y + style.FramePadding.y * 2.0f);

    const ImRect bb = ImRect(pos, pos + size);
    ItemSize(size, style.FramePadding.y);
    if (!ItemAdd(bb, id))
        return false;

    if (g.LastItemData.InFlags & ImGuiItemFlags.ButtonRepeat)
        flags |= ImGuiButtonFlags.Repeat;

    bool hovered, held;
    bool pressed = ButtonBehavior(bb, id, &hovered, &held, flags);

    // Render
    const ImU32 col = GetColorU32((held && hovered) ? ImGuiCol.ButtonActive : hovered ? ImGuiCol.ButtonHovered : ImGuiCol.Button);
    RenderNavHighlight(bb, id);
    RenderFrame(bb.Min, bb.Max, col, true, style.FrameRounding);

    if (g.LogEnabled)
        LogSetNextTextDecoration("[", "]");
    RenderTextClipped(bb.Min + style.FramePadding, bb.Max - style.FramePadding, label, &label_size, style.ButtonTextAlign, &bb);

    // Automatically close popups
    //if (pressed && !(flags & ImGuiButtonFlags_DontClosePopups) && (window->Flags & ImGuiWindowFlags_Popup))
    //    CloseCurrentPopup();

    IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags);
    return pressed;
}

bool Button(string label, const ImVec2/*&*/ size_arg = ImVec2(0, 0))
{
    return ButtonEx(label, size_arg, ImGuiButtonFlags.None);
}

// Small buttons fits within text without additional vertical spacing.
bool SmallButton(string label)
{
    ImGuiContext* g = GImGui;
    float backup_padding_y = g.Style.FramePadding.y;
    g.Style.FramePadding.y = 0.0f;
    bool pressed = ButtonEx(label, ImVec2(0, 0), ImGuiButtonFlags.AlignTextBaseLine);
    g.Style.FramePadding.y = backup_padding_y;
    return pressed;
}

// Tip: use ImGui::PushID()/PopID() to push indices or pointers in the ID stack.
// Then you can keep 'str_id' empty or the same for all your buttons (instead of creating a string based on a non-string id)
bool InvisibleButton(string str_id, const ImVec2/*&*/ size_arg, ImGuiButtonFlags flags = ImGuiButtonFlags.None)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    // Cannot use zero-size for InvisibleButton(). Unlike Button() there is not way to fallback using the label size.
    IM_ASSERT(size_arg.x != 0.0f && size_arg.y != 0.0f);

    const ImGuiID id = window.GetID(str_id);
    ImVec2 size = CalcItemSize(size_arg, 0.0f, 0.0f);
    const ImRect bb = ImRect(window.DC.CursorPos, window.DC.CursorPos + size);
    ItemSize(size);
    if (!ItemAdd(bb, id))
        return false;

    bool hovered, held;
    bool pressed = ButtonBehavior(bb, id, &hovered, &held, flags);

    return pressed;
}

bool ArrowButtonEx(string str_id, ImGuiDir dir, ImVec2 size, ImGuiButtonFlags flags = ImGuiButtonFlags.None)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    ImGuiContext* g = GImGui;
    const ImGuiID id = window.GetID(str_id);
    const ImRect bb = ImRect(window.DC.CursorPos, window.DC.CursorPos + size);
    const float default_size = GetFrameHeight();
    ItemSize(size, (size.y >= default_size) ? g.Style.FramePadding.y : -1.0f);
    if (!ItemAdd(bb, id))
        return false;

    if (g.LastItemData.InFlags & ImGuiItemFlags.ButtonRepeat)
        flags |= ImGuiButtonFlags.Repeat;

    bool hovered, held;
    bool pressed = ButtonBehavior(bb, id, &hovered, &held, flags);

    // Render
    const ImU32 bg_col = GetColorU32((held && hovered) ? ImGuiCol.ButtonActive : hovered ? ImGuiCol.ButtonHovered : ImGuiCol.Button);
    const ImU32 text_col = GetColorU32(ImGuiCol.Text);
    RenderNavHighlight(bb, id);
    RenderFrame(bb.Min, bb.Max, bg_col, true, g.Style.FrameRounding);
    RenderArrow(window.DrawList, bb.Min + ImVec2(ImMax(0.0f, (size.x - g.FontSize) * 0.5f), ImMax(0.0f, (size.y - g.FontSize) * 0.5f)), text_col, dir);

    return pressed;
}

bool ArrowButton(string str_id, ImGuiDir dir)
{
    float sz = GetFrameHeight();
    return ArrowButtonEx(str_id, dir, ImVec2(sz, sz), ImGuiButtonFlags.None);
}

// Button to close a window
bool CloseButton(ImGuiID id, const ImVec2/*&*/ pos)
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;

    // Tweak 1: Shrink hit-testing area if button covers an abnormally large proportion of the visible region. That's in order to facilitate moving the window away. (#3825)
    // This may better be applied as a general hit-rect reduction mechanism for all widgets to ensure the area to move window is always accessible?
    const ImRect bb = ImRect(pos, pos + ImVec2(g.FontSize, g.FontSize) + g.Style.FramePadding * 2.0f);
    ImRect bb_interact = bb;
    const float area_to_visible_ratio = window.OuterRectClipped.GetArea() / bb.GetArea();
    if (area_to_visible_ratio < 1.5f)
        bb_interact.Expand(ImFloor(bb_interact.GetSize() * -0.25f));

    // Tweak 2: We intentionally allow interaction when clipped so that a mechanical Alt,Right,Activate sequence can always close a window.
    // (this isn't the regular behavior of buttons, but it doesn't affect the user much because navigation tends to keep items visible).
    bool is_clipped = !ItemAdd(bb_interact, id);

    bool hovered, held;
    bool pressed = ButtonBehavior(bb_interact, id, &hovered, &held);
    if (is_clipped)
        return pressed;

    // Render
    // FIXME: Clarify this mess
    ImU32 col = GetColorU32(held ? ImGuiCol.ButtonActive : ImGuiCol.ButtonHovered);
    ImVec2 center = bb.GetCenter();
    if (hovered)
        window.DrawList.AddCircleFilled(center, ImMax(2.0f, g.FontSize * 0.5f + 1.0f), col, 12);

    float cross_extent = g.FontSize * 0.5f * 0.7071f - 1.0f;
    ImU32 cross_col = GetColorU32(ImGuiCol.Text);
    center -= ImVec2(0.5f, 0.5f);
    window.DrawList.AddLine(center + ImVec2(+cross_extent, +cross_extent), center + ImVec2(-cross_extent, -cross_extent), cross_col, 1.0f);
    window.DrawList.AddLine(center + ImVec2(+cross_extent, -cross_extent), center + ImVec2(-cross_extent, +cross_extent), cross_col, 1.0f);

    return pressed;
}

bool CollapseButton(ImGuiID id, const ImVec2/*&*/ pos)
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;

    ImRect bb = ImRect(pos, pos + ImVec2(g.FontSize, g.FontSize) + g.Style.FramePadding * 2.0f);
    ItemAdd(bb, id);
    bool hovered, held;
    bool pressed = ButtonBehavior(bb, id, &hovered, &held, ImGuiButtonFlags.None);

    // Render
    ImU32 bg_col = GetColorU32((held && hovered) ? ImGuiCol.ButtonActive : hovered ? ImGuiCol.ButtonHovered : ImGuiCol.Button);
    ImU32 text_col = GetColorU32(ImGuiCol.Text);
    ImVec2 center = bb.GetCenter();
    if (hovered || held)
        window.DrawList.AddCircleFilled(center/*+ ImVec2(0.0f, -0.5f)*/, g.FontSize * 0.5f + 1.0f, bg_col, 12);
    RenderArrow(window.DrawList, bb.Min + g.Style.FramePadding, text_col, window.Collapsed ? ImGuiDir.Right : ImGuiDir.Down, 1.0f);

    // Switch to moving the window after mouse is moved beyond the initial drag threshold
    if (IsItemActive() && IsMouseDragging(ImGuiMouseButton.Left))
        StartMouseMovingWindow(window);

    return pressed;
}

ImGuiID GetWindowScrollbarID(ImGuiWindow* window, ImGuiAxis axis)
{
    return window.GetIDNoKeepAlive(axis == ImGuiAxis.X ? "#SCROLLX" : "#SCROLLY");
}

// Return scrollbar rectangle, must only be called for corresponding axis if window->ScrollbarX/Y is set.
ImRect GetWindowScrollbarRect(ImGuiWindow* window, ImGuiAxis axis)
{
    const ImRect outer_rect = window.Rect();
    const ImRect inner_rect = window.InnerRect;
    const float border_size = window.WindowBorderSize;
    const float scrollbar_size = window.ScrollbarSizes[axis ^ 1]; // (ScrollbarSizes.x = width of Y scrollbar; ScrollbarSizes.y = height of X scrollbar)
    IM_ASSERT(scrollbar_size > 0.0f);
    if (axis == ImGuiAxis.X)
        return ImRect(inner_rect.Min.x, ImMax(outer_rect.Min.y, outer_rect.Max.y - border_size - scrollbar_size), inner_rect.Max.x, outer_rect.Max.y);
    else
        return ImRect(ImMax(outer_rect.Min.x, outer_rect.Max.x - border_size - scrollbar_size), inner_rect.Min.y, outer_rect.Max.x, inner_rect.Max.y);
}

void Scrollbar(ImGuiAxis axis)
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;

    const ImGuiID id = GetWindowScrollbarID(window, axis);
    KeepAliveID(id);

    // Calculate scrollbar bounding box
    ImRect bb = GetWindowScrollbarRect(window, axis);
    ImDrawFlags rounding_corners = ImDrawFlags.RoundCornersNone;
    if (axis == ImGuiAxis.X)
    {
        rounding_corners |= ImDrawFlags.RoundCornersBottomLeft;
        if (!window.ScrollbarY)
            rounding_corners |= ImDrawFlags.RoundCornersBottomRight;
    }
    else
    {
        if ((window.Flags & ImGuiWindowFlags.NoTitleBar) && !(window.Flags & ImGuiWindowFlags.MenuBar))
            rounding_corners |= ImDrawFlags.RoundCornersTopRight;
        if (!window.ScrollbarX)
            rounding_corners |= ImDrawFlags.RoundCornersBottomRight;
    }
    float size_avail = window.InnerRect.Max[axis] - window.InnerRect.Min[axis];
    float size_contents = window.ContentSize[axis] + window.WindowPadding[axis] * 2.0f;
    ScrollbarEx(bb, id, axis, &window.Scroll[axis], size_avail, size_contents, rounding_corners);
}

// Vertical/Horizontal scrollbar
// The entire piece of code below is rather confusing because:
// - We handle absolute seeking (when first clicking outside the grab) and relative manipulation (afterward or when clicking inside the grab)
// - We store values as normalized ratio and in a form that allows the window content to change while we are holding on a scrollbar
// - We handle both horizontal and vertical scrollbars, which makes the terminology not ideal.
// Still, the code should probably be made simpler..
bool ScrollbarEx(const ImRect/*&*/ bb_frame, ImGuiID id, ImGuiAxis axis, float* p_scroll_v, float size_avail_v, float size_contents_v, ImDrawFlags flags)
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;
    if (window.SkipItems)
        return false;

    const float bb_frame_width = bb_frame.GetWidth();
    const float bb_frame_height = bb_frame.GetHeight();
    if (bb_frame_width <= 0.0f || bb_frame_height <= 0.0f)
        return false;

    // When we are too small, start hiding and disabling the grab (this reduce visual noise on very small window and facilitate using the window resize grab)
    float alpha = 1.0f;
    if ((axis == ImGuiAxis.Y) && bb_frame_height < g.FontSize + g.Style.FramePadding.y * 2.0f)
        alpha = ImSaturate((bb_frame_height - g.FontSize) / (g.Style.FramePadding.y * 2.0f));
    if (alpha <= 0.0f)
        return false;

    const ImGuiStyle* style = &g.Style;
    const bool allow_interaction = (alpha >= 1.0f);

    ImRect bb = bb_frame;
    bb.Expand(ImVec2(-ImClamp(IM_FLOOR((bb_frame_width - 2.0f) * 0.5f), 0.0f, 3.0f), -ImClamp(IM_FLOOR((bb_frame_height - 2.0f) * 0.5f), 0.0f, 3.0f)));

    // V denote the main, longer axis of the scrollbar (= height for a vertical scrollbar)
    const float scrollbar_size_v = (axis == ImGuiAxis.X) ? bb.GetWidth() : bb.GetHeight();

    // Calculate the height of our grabbable box. It generally represent the amount visible (vs the total scrollable amount)
    // But we maintain a minimum size in pixel to allow for the user to still aim inside.
    IM_ASSERT(ImMax(size_contents_v, size_avail_v) > 0.0f); // Adding this assert to check if the ImMax(XXX,1.0f) is still needed. PLEASE CONTACT ME if this triggers.
    const float win_size_v = ImMax(ImMax(size_contents_v, size_avail_v), 1.0f);
    const float grab_h_pixels = ImClamp(scrollbar_size_v * (size_avail_v / win_size_v), style.GrabMinSize, scrollbar_size_v);
    const float grab_h_norm = grab_h_pixels / scrollbar_size_v;

    // Handle input right away. None of the code of Begin() is relying on scrolling position before calling Scrollbar().
    bool held = false;
    bool hovered = false;
    ButtonBehavior(bb, id, &hovered, &held, ImGuiButtonFlags.NoNavFocus);

    float scroll_max = ImMax(1.0f, size_contents_v - size_avail_v);
    float scroll_ratio = ImSaturate(*p_scroll_v / scroll_max);
    float grab_v_norm = scroll_ratio * (scrollbar_size_v - grab_h_pixels) / scrollbar_size_v; // Grab position in normalized space
    if (held && allow_interaction && grab_h_norm < 1.0f)
    {
        float scrollbar_pos_v = bb.Min[axis];
        float mouse_pos_v = g.IO.MousePos[axis];

        // Click position in scrollbar normalized space (0.0f->1.0f)
        const float clicked_v_norm = ImSaturate((mouse_pos_v - scrollbar_pos_v) / scrollbar_size_v);
        SetHoveredID(id);

        bool seek_absolute = false;
        if (g.ActiveIdIsJustActivated)
        {
            // On initial click calculate the distance between mouse and the center of the grab
            seek_absolute = (clicked_v_norm < grab_v_norm || clicked_v_norm > grab_v_norm + grab_h_norm);
            if (seek_absolute)
                g.ScrollbarClickDeltaToGrabCenter = 0.0f;
            else
                g.ScrollbarClickDeltaToGrabCenter = clicked_v_norm - grab_v_norm - grab_h_norm * 0.5f;
        }

        // Apply scroll (p_scroll_v will generally point on one member of window->Scroll)
        // It is ok to modify Scroll here because we are being called in Begin() after the calculation of ContentSize and before setting up our starting position
        const float scroll_v_norm = ImSaturate((clicked_v_norm - g.ScrollbarClickDeltaToGrabCenter - grab_h_norm * 0.5f) / (1.0f - grab_h_norm));
        *p_scroll_v = IM_ROUND(scroll_v_norm * scroll_max);//(win_size_contents_v - win_size_v));

        // Update values for rendering
        scroll_ratio = ImSaturate(*p_scroll_v / scroll_max);
        grab_v_norm = scroll_ratio * (scrollbar_size_v - grab_h_pixels) / scrollbar_size_v;

        // Update distance to grab now that we have seeked and saturated
        if (seek_absolute)
            g.ScrollbarClickDeltaToGrabCenter = clicked_v_norm - grab_v_norm - grab_h_norm * 0.5f;
    }

    // Render
    const ImU32 bg_col = GetColorU32(ImGuiCol.ScrollbarBg);
    const ImU32 grab_col = GetColorU32(held ? ImGuiCol.ScrollbarGrabActive : hovered ? ImGuiCol.ScrollbarGrabHovered : ImGuiCol.ScrollbarGrab, alpha);
    window.DrawList.AddRectFilled(bb_frame.Min, bb_frame.Max, bg_col, window.WindowRounding, flags);
    ImRect grab_rect;
    if (axis == ImGuiAxis.X)
        grab_rect = ImRect(ImLerp(bb.Min.x, bb.Max.x, grab_v_norm), bb.Min.y, ImLerp(bb.Min.x, bb.Max.x, grab_v_norm) + grab_h_pixels, bb.Max.y);
    else
        grab_rect = ImRect(bb.Min.x, ImLerp(bb.Min.y, bb.Max.y, grab_v_norm), bb.Max.x, ImLerp(bb.Min.y, bb.Max.y, grab_v_norm) + grab_h_pixels);
    window.DrawList.AddRectFilled(grab_rect.Min, grab_rect.Max, grab_col, style.ScrollbarRounding);

    return held;
}

void Image(ImTextureID user_texture_id, const ImVec2/*&*/ size, const ImVec2/*&*/ uv0 = ImVec2(0, 0), const ImVec2/*&*/ uv1 = ImVec2(1,1), const ImVec4/*&*/ tint_col = ImVec4(1,1,1,1), const ImVec4/*&*/ border_col = ImVec4(0,0,0,0))
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return;

    ImRect bb = ImRect(window.DC.CursorPos, window.DC.CursorPos + size);
    if (border_col.w > 0.0f)
        bb.Max += ImVec2(2, 2);
    ItemSize(bb);
    if (!ItemAdd(bb, 0))
        return;

    if (border_col.w > 0.0f)
    {
        window.DrawList.AddRect(bb.Min, bb.Max, GetColorU32(border_col), 0.0f);
        window.DrawList.AddImage(user_texture_id, bb.Min + ImVec2(1, 1), bb.Max - ImVec2(1, 1), uv0, uv1, GetColorU32(tint_col));
    }
    else
    {
        window.DrawList.AddImage(user_texture_id, bb.Min, bb.Max, uv0, uv1, GetColorU32(tint_col));
    }
}

// ImageButton() is flawed as 'id' is always derived from 'texture_id' (see #2464 #1390)
// We provide this internal helper to write your own variant while we figure out how to redesign the public ImageButton() API.
bool ImageButtonEx(ImGuiID id, ImTextureID texture_id, const ImVec2/*&*/ size, const ImVec2/*&*/ uv0, const ImVec2/*&*/ uv1, const ImVec2/*&*/ padding, const ImVec4/*&*/ bg_col, const ImVec4/*&*/ tint_col)
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    const ImRect bb = ImRect(window.DC.CursorPos, window.DC.CursorPos + size + padding * 2);
    ItemSize(bb);
    if (!ItemAdd(bb, id))
        return false;

    bool hovered, held;
    bool pressed = ButtonBehavior(bb, id, &hovered, &held);

    // Render
    const ImU32 col = GetColorU32((held && hovered) ? ImGuiCol.ButtonActive : hovered ? ImGuiCol.ButtonHovered : ImGuiCol.Button);
    RenderNavHighlight(bb, id);
    RenderFrame(bb.Min, bb.Max, col, true, ImClamp(cast(float)ImMin(padding.x, padding.y), 0.0f, g.Style.FrameRounding));
    if (bg_col.w > 0.0f)
        window.DrawList.AddRectFilled(bb.Min + padding, bb.Max - padding, GetColorU32(bg_col));
    window.DrawList.AddImage(texture_id, bb.Min + padding, bb.Max - padding, uv0, uv1, GetColorU32(tint_col));

    return pressed;
}

// frame_padding < 0: uses FramePadding from style (default)
// frame_padding = 0: no framing
// frame_padding > 0: set framing size
bool ImageButton(ImTextureID user_texture_id, const ImVec2/*&*/ size, const ImVec2/*&*/ uv0 = ImVec2(0, 0),  const ImVec2/*&*/ uv1 = ImVec2(1,1), int frame_padding = -1, const ImVec4/*&*/ bg_col = ImVec4(0,0,0,0), const ImVec4/*&*/ tint_col = ImVec4(1,1,1,1))
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;
    if (window.SkipItems)
        return false;

    // Default to using texture ID as ID. User can still push string/integer prefixes.
    PushID(cast(void*)cast(intptr_t)user_texture_id);
    const ImGuiID id = window.GetID("#image");
    PopID();

    const ImVec2 padding = (frame_padding >= 0) ? ImVec2(cast(float)frame_padding, cast(float)frame_padding) : g.Style.FramePadding;
    return ImageButtonEx(id, user_texture_id, size, uv0, uv1, padding, bg_col, tint_col);
}

bool Checkbox(string label, bool* v)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    ImGuiContext* g = GImGui;
    const ImGuiStyle* style = &g.Style;
    const ImGuiID id = window.GetID(label);
    const ImVec2 label_size = CalcTextSize(label, true);

    const float square_sz = GetFrameHeight();
    const ImVec2 pos = window.DC.CursorPos;
    const ImRect total_bb = ImRect(pos, pos + ImVec2(square_sz + (label_size.x > 0.0f ? style.ItemInnerSpacing.x + label_size.x : 0.0f), label_size.y + style.FramePadding.y * 2.0f));
    ItemSize(total_bb, style.FramePadding.y);
    if (!ItemAdd(total_bb, id))
    {
        IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags | ImGuiItemStatusFlags.Checkable | (*v ? ImGuiItemStatusFlags.Checked : ImGuiItemStatusFlags.None));
        return false;
    }

    bool hovered, held;
    bool pressed = ButtonBehavior(total_bb, id, &hovered, &held);
    if (pressed)
    {
        *v = !(*v);
        MarkItemEdited(id);
    }

    const ImRect check_bb = ImRect(pos, pos + ImVec2(square_sz, square_sz));
    RenderNavHighlight(total_bb, id);
    RenderFrame(check_bb.Min, check_bb.Max, GetColorU32((held && hovered) ? ImGuiCol.FrameBgActive : hovered ? ImGuiCol.FrameBgHovered : ImGuiCol.FrameBg), true, style.FrameRounding);
    ImU32 check_col = GetColorU32(ImGuiCol.CheckMark);
    bool mixed_value = (g.LastItemData.InFlags & ImGuiItemFlags.MixedValue) != 0;
    if (mixed_value)
    {
        // Undocumented tristate/mixed/indeterminate checkbox (#2644)
        // This may seem awkwardly designed because the aim is to make ImGuiItemFlags_MixedValue supported by all widgets (not just checkbox)
        ImVec2 pad = ImVec2(ImMax(1.0f, IM_FLOOR(square_sz / 3.6f)), ImMax(1.0f, IM_FLOOR(square_sz / 3.6f)));
        window.DrawList.AddRectFilled(check_bb.Min + pad, check_bb.Max - pad, check_col, style.FrameRounding);
    }
    else if (*v)
    {
        const float pad = ImMax(1.0f, IM_FLOOR(square_sz / 6.0f));
        RenderCheckMark(window.DrawList, check_bb.Min + ImVec2(pad, pad), check_col, square_sz - pad * 2.0f);
    }

    ImVec2 label_pos = ImVec2(check_bb.Max.x + style.ItemInnerSpacing.x, check_bb.Min.y + style.FramePadding.y);
    if (g.LogEnabled)
        LogRenderedText(&label_pos, mixed_value ? "[~]" : *v ? "[x]" : "[ ]");
    if (label_size.x > 0.0f)
        RenderText(label_pos, label);

    IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags | ImGuiItemStatusFlags.Checkable | (*v ? ImGuiItemStatusFlags.Checked : ImGuiItemStatusFlags.None));
    return pressed;
}

bool CheckboxFlagsT(T)(string label, T* flags, T flags_value)
{
    bool all_on = (*flags & flags_value) == flags_value;
    bool any_on = (*flags & flags_value) != 0;
    bool pressed;
    if (!all_on && any_on)
    {
        ImGuiContext* g = GImGui;
        ImGuiItemFlags backup_item_flags = g.CurrentItemFlags;
        g.CurrentItemFlags |= ImGuiItemFlags.MixedValue;
        pressed = Checkbox(label, &all_on);
        g.CurrentItemFlags = backup_item_flags;
    }
    else
    {
        pressed = Checkbox(label, &all_on);

    }
    if (pressed)
    {
        if (all_on)
            *flags |= flags_value;
        else
            *flags &= ~flags_value;
    }
    return pressed;
}

bool CheckboxFlags(string label, int* flags, int flags_value)
{
    return CheckboxFlagsT(label, flags, flags_value);
}

bool CheckboxFlags(string label, uint* flags, uint flags_value)
{
    return CheckboxFlagsT(label, flags, flags_value);
}

bool CheckboxFlags(string label, ImS64* flags, ImS64 flags_value)
{
    return CheckboxFlagsT(label, flags, flags_value);
}

bool CheckboxFlags(string label, ImU64* flags, ImU64 flags_value)
{
    return CheckboxFlagsT(label, flags, flags_value);
}

bool CheckboxFlags(T)(string label, T* flags, T flags_value) if (is(T == enum))
{
    return CheckboxFlagsT(label, flags, flags_value);
}

bool RadioButton(string label, bool active)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    ImGuiContext* g = GImGui;
    const ImGuiStyle* style = &g.Style;
    const ImGuiID id = window.GetID(label);
    const ImVec2 label_size = CalcTextSize(label, true);

    const float square_sz = GetFrameHeight();
    const ImVec2 pos = window.DC.CursorPos;
    const ImRect check_bb = ImRect(pos, pos + ImVec2(square_sz, square_sz));
    const ImRect total_bb = ImRect(pos, pos + ImVec2(square_sz + (label_size.x > 0.0f ? style.ItemInnerSpacing.x + label_size.x : 0.0f), label_size.y + style.FramePadding.y * 2.0f));
    ItemSize(total_bb, style.FramePadding.y);
    if (!ItemAdd(total_bb, id))
        return false;

    ImVec2 center = check_bb.GetCenter();
    center.x = IM_ROUND(center.x);
    center.y = IM_ROUND(center.y);
    const float radius = (square_sz - 1.0f) * 0.5f;

    bool hovered, held;
    bool pressed = ButtonBehavior(total_bb, id, &hovered, &held);
    if (pressed)
        MarkItemEdited(id);

    RenderNavHighlight(total_bb, id);
    window.DrawList.AddCircleFilled(center, radius, GetColorU32((held && hovered) ? ImGuiCol.FrameBgActive : hovered ? ImGuiCol.FrameBgHovered : ImGuiCol.FrameBg), 16);
    if (active)
    {
        const float pad = ImMax(1.0f, IM_FLOOR(square_sz / 6.0f));
        window.DrawList.AddCircleFilled(center, radius - pad, GetColorU32(ImGuiCol.CheckMark), 16);
    }

    if (style.FrameBorderSize > 0.0f)
    {
        window.DrawList.AddCircle(center + ImVec2(1, 1), radius, GetColorU32(ImGuiCol.BorderShadow), 16, style.FrameBorderSize);
        window.DrawList.AddCircle(center, radius, GetColorU32(ImGuiCol.Border), 16, style.FrameBorderSize);
    }

    ImVec2 label_pos = ImVec2(check_bb.Max.x + style.ItemInnerSpacing.x, check_bb.Min.y + style.FramePadding.y);
    if (g.LogEnabled)
        LogRenderedText(&label_pos, active ? "(x)" : "( )");
    if (label_size.x > 0.0f)
        RenderText(label_pos, label);

    IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags);
    return pressed;
}

// FIXME: This would work nicely if it was a public template, e.g. 'template<T> RadioButton(const char* label, T* v, T v_button)', but I'm not sure how we would expose it..
bool RadioButton(string label, int* v, int v_button)
{
    const bool pressed = RadioButton(label, *v == v_button);
    if (pressed)
        *v = v_button;
    return pressed;
}

// size_arg (for each axis) < 0.0f: align to end, 0.0f: auto, > 0.0f: specified size
void ProgressBar(float fraction, const ImVec2/*&*/ size_arg = ImVec2(-1, 0), string overlay = NULL)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return;

    ImGuiContext* g = GImGui;
    const ImGuiStyle* style = &g.Style;

    ImVec2 pos = window.DC.CursorPos;
    ImVec2 size = CalcItemSize(size_arg, CalcItemWidth(), g.FontSize + style.FramePadding.y * 2.0f);
    ImRect bb = ImRect(pos, pos + size);
    ItemSize(size, style.FramePadding.y);
    if (!ItemAdd(bb, 0))
        return;

    // Render
    fraction = ImSaturate(fraction);
    RenderFrame(bb.Min, bb.Max, GetColorU32(ImGuiCol.FrameBg), true, style.FrameRounding);
    bb.Expand(ImVec2(-style.FrameBorderSize, -style.FrameBorderSize));
    const ImVec2 fill_br = ImVec2(ImLerp(bb.Min.x, bb.Max.x, fraction), bb.Max.y);
    RenderRectFilledRangeH(window.DrawList, bb, GetColorU32(ImGuiCol.PlotHistogram), 0.0f, fraction, style.FrameRounding);

    // Default displaying the fraction as percentage string, but user can override it
    char[32] overlay_buf;
    if (!overlay)
    {
        int index = ImFormatString(overlay_buf, "%.0f%%", fraction * 100 + 0.01f);
        overlay = cast(string)overlay_buf[0..index];
    }

    ImVec2 overlay_size = CalcTextSize(overlay);
    if (overlay_size.x > 0.0f)
        RenderTextClipped(ImVec2(ImClamp(fill_br.x + style.ItemSpacing.x, bb.Min.x, bb.Max.x - overlay_size.x - style.ItemInnerSpacing.x), bb.Min.y), bb.Max, overlay, &overlay_size, ImVec2(0.0f, 0.5f), &bb);
}

void Bullet()
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return;

    ImGuiContext* g = GImGui;
    const ImGuiStyle* style = &g.Style;
    const float line_height = ImMax(ImMin(window.DC.CurrLineSize.y, g.FontSize + g.Style.FramePadding.y * 2), g.FontSize);
    const ImRect bb = ImRect(window.DC.CursorPos, window.DC.CursorPos + ImVec2(g.FontSize, line_height));
    ItemSize(bb);
    if (!ItemAdd(bb, 0))
    {
        SameLine(0, style.FramePadding.x * 2);
        return;
    }

    // Render and stay on same line
    ImU32 text_col = GetColorU32(ImGuiCol.Text);
    RenderBullet(window.DrawList, bb.Min + ImVec2(style.FramePadding.x + g.FontSize * 0.5f, line_height * 0.5f), text_col);
    SameLine(0, style.FramePadding.x * 2.0f);
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: Low-level Layout helpers
//-------------------------------------------------------------------------
// - Spacing()
// - Dummy()
// - NewLine()
// - AlignTextToFramePadding()
// - SeparatorEx() [Internal]
// - Separator()
// - SplitterBehavior() [Internal]
// - ShrinkWidths() [Internal]
//-------------------------------------------------------------------------

void Spacing()
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return;
    ItemSize(ImVec2(0, 0));
}

void Dummy(const ImVec2/*&*/ size)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return;

    const ImRect bb = ImRect(window.DC.CursorPos, window.DC.CursorPos + size);
    ItemSize(size);
    ItemAdd(bb, 0);
}

void NewLine()
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return;

    ImGuiContext* g = GImGui;
    const ImGuiLayoutType backup_layout_type = window.DC.LayoutType;
    window.DC.LayoutType = ImGuiLayoutType.Vertical;
    if (window.DC.CurrLineSize.y > 0.0f)     // In the event that we are on a line with items that is smaller that FontSize high, we will preserve its height.
        ItemSize(ImVec2(0, 0));
    else
        ItemSize(ImVec2(0.0f, g.FontSize));
    window.DC.LayoutType = backup_layout_type;
}

void AlignTextToFramePadding()
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return;

    ImGuiContext* g = GImGui;
    window.DC.CurrLineSize.y = ImMax(window.DC.CurrLineSize.y, g.FontSize + g.Style.FramePadding.y * 2);
    window.DC.CurrLineTextBaseOffset = ImMax(window.DC.CurrLineTextBaseOffset, g.Style.FramePadding.y);
}

// Horizontal/vertical separating line
void SeparatorEx(ImGuiSeparatorFlags flags)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return;

    ImGuiContext* g = GImGui;
    IM_ASSERT(ImIsPowerOfTwo(flags & (ImGuiSeparatorFlags.Horizontal | ImGuiSeparatorFlags.Vertical)));   // Check that only 1 option is selected

    float thickness_draw = 1.0f;
    float thickness_layout = 0.0f;
    if (flags & ImGuiSeparatorFlags.Vertical)
    {
        // Vertical separator, for menu bars (use current line height). Not exposed because it is misleading and it doesn't have an effect on regular layout.
        float y1 = window.DC.CursorPos.y;
        float y2 = window.DC.CursorPos.y + window.DC.CurrLineSize.y;
        const ImRect bb = ImRect(ImVec2(window.DC.CursorPos.x, y1), ImVec2(window.DC.CursorPos.x + thickness_draw, y2));
        ItemSize(ImVec2(thickness_layout, 0.0f));
        if (!ItemAdd(bb, 0))
            return;

        // Draw
        window.DrawList.AddLine(ImVec2(bb.Min.x, bb.Min.y), ImVec2(bb.Min.x, bb.Max.y), GetColorU32(ImGuiCol.Separator));
        if (g.LogEnabled)
            LogText(" |");
    }
    else if (flags & ImGuiSeparatorFlags.Horizontal)
    {
        // Horizontal Separator
        float x1 = window.Pos.x;
        float x2 = window.Pos.x + window.Size.x;

        // FIXME-WORKRECT: old hack (#205) until we decide of consistent behavior with WorkRect/Indent and Separator
        if (g.GroupStack.Size > 0 && g.GroupStack.back().WindowID == window.ID)
            x1 += window.DC.Indent.x;

        ImGuiOldColumns* columns = (flags & ImGuiSeparatorFlags.SpanAllColumns) ? window.DC.CurrentColumns : NULL;
        if (columns)
            PushColumnsBackground();

        // We don't provide our width to the layout so that it doesn't get feed back into AutoFit
        const ImRect bb = ImRect(ImVec2(x1, window.DC.CursorPos.y), ImVec2(x2, window.DC.CursorPos.y + thickness_draw));
        ItemSize(ImVec2(0.0f, thickness_layout));
        const bool item_visible = ItemAdd(bb, 0);
        if (item_visible)
        {
            // Draw
            window.DrawList.AddLine(bb.Min, ImVec2(bb.Max.x, bb.Min.y), GetColorU32(ImGuiCol.Separator));
            if (g.LogEnabled)
                LogRenderedText(&bb.Min, "--------------------------------\n");

        }
        if (columns)
        {
            PopColumnsBackground();
            columns.LineMinY = window.DC.CursorPos.y;
        }
    }
}

void Separator()
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;
    if (window.SkipItems)
        return;

    // Those flags should eventually be overridable by the user
    ImGuiSeparatorFlags flags = (window.DC.LayoutType == ImGuiLayoutType.Horizontal) ? ImGuiSeparatorFlags.Vertical : ImGuiSeparatorFlags.Horizontal;
    flags |= ImGuiSeparatorFlags.SpanAllColumns;
    SeparatorEx(flags);
}

// Using 'hover_visibility_delay' allows us to hide the highlight and mouse cursor for a short time, which can be convenient to reduce visual noise.
bool SplitterBehavior(const ImRect/*&*/ bb, ImGuiID id, ImGuiAxis axis, float* size1, float* size2, float min_size1, float min_size2, float hover_extend = 0.0f, float hover_visibility_delay = 0.0f)
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;

    const ImGuiItemFlags item_flags_backup = g.CurrentItemFlags;
    g.CurrentItemFlags |= ImGuiItemFlags.NoNav | ImGuiItemFlags.NoNavDefaultFocus;
    bool item_add = ItemAdd(bb, id);
    g.CurrentItemFlags = item_flags_backup;
    if (!item_add)
        return false;

    bool hovered, held;
    ImRect bb_interact = bb;
    bb_interact.Expand(axis == ImGuiAxis.Y ? ImVec2(0.0f, hover_extend) : ImVec2(hover_extend, 0.0f));
    ButtonBehavior(bb_interact, id, &hovered, &held, ImGuiButtonFlags.FlattenChildren | ImGuiButtonFlags.AllowItemOverlap);
    if (hovered)
        g.LastItemData.StatusFlags |= ImGuiItemStatusFlags.HoveredRect; // for IsItemHovered(), because bb_interact is larger than bb
    if (g.ActiveId != id)
        SetItemAllowOverlap();

    if (held || (hovered && g.HoveredIdPreviousFrame == id && g.HoveredIdTimer >= hover_visibility_delay))
        SetMouseCursor(axis == ImGuiAxis.Y ? ImGuiMouseCursor.ResizeNS : ImGuiMouseCursor.ResizeEW);

    ImRect bb_render = bb;
    if (held)
    {
        ImVec2 mouse_delta_2d = g.IO.MousePos - g.ActiveIdClickOffset - bb_interact.Min;
        float mouse_delta = (axis == ImGuiAxis.Y) ? mouse_delta_2d.y : mouse_delta_2d.x;

        // Minimum pane size
        float size_1_maximum_delta = ImMax(0.0f, *size1 - min_size1);
        float size_2_maximum_delta = ImMax(0.0f, *size2 - min_size2);
        if (mouse_delta < -size_1_maximum_delta)
            mouse_delta = -size_1_maximum_delta;
        if (mouse_delta > size_2_maximum_delta)
            mouse_delta = size_2_maximum_delta;

        // Apply resize
        if (mouse_delta != 0.0f)
        {
            if (mouse_delta < 0.0f)
                IM_ASSERT(*size1 + mouse_delta >= min_size1);
            if (mouse_delta > 0.0f)
                IM_ASSERT(*size2 - mouse_delta >= min_size2);
            *size1 += mouse_delta;
            *size2 -= mouse_delta;
            bb_render.Translate((axis == ImGuiAxis.X) ? ImVec2(mouse_delta, 0.0f) : ImVec2(0.0f, mouse_delta));
            MarkItemEdited(id);
        }
    }

    // Render
    const ImU32 col = GetColorU32(held ? ImGuiCol.SeparatorActive : (hovered && g.HoveredIdTimer >= hover_visibility_delay) ? ImGuiCol.SeparatorHovered : ImGuiCol.Separator);
    window.DrawList.AddRectFilled(bb_render.Min, bb_render.Max, col, 0.0f);

    return held;
}

int ShrinkWidthItemComparer(const ImGuiShrinkWidthItem* a, const ImGuiShrinkWidthItem* b)
{
    if (int d = cast(int)(b.Width - a.Width))
        return d;
    return (b.Index - a.Index);
}

// Shrink excess width from a set of item, by removing width from the larger items first.
// Set items Width to -1.0f to disable shrinking this item.
void ShrinkWidths(ImGuiShrinkWidthItem* items, int count, float width_excess)
{
    if (count == 1)
    {
        if (items[0].Width >= 0.0f)
            items[0].Width = ImMax(items[0].Width - width_excess, 1.0f);
        return;
    }
    ImQsort(items[0..cast(size_t)count], &ShrinkWidthItemComparer);
    int count_same_width = 1;
    while (width_excess > 0.0f && count_same_width < count)
    {
        while (count_same_width < count && items[0].Width <= items[count_same_width].Width)
            count_same_width++;
        float max_width_to_remove_per_item = (count_same_width < count && items[count_same_width].Width >= 0.0f) ? (items[0].Width - items[count_same_width].Width) : (items[0].Width - 1.0f);
        if (max_width_to_remove_per_item <= 0.0f)
            break;
        float width_to_remove_per_item = ImMin(width_excess / count_same_width, max_width_to_remove_per_item);
        for (int item_n = 0; item_n < count_same_width; item_n++)
            items[item_n].Width -= width_to_remove_per_item;
        width_excess -= width_to_remove_per_item * count_same_width;
    }

    // Round width and redistribute remainder left-to-right (could make it an option of the function?)
    // Ensure that e.g. the right-most tab of a shrunk tab-bar always reaches exactly at the same distance from the right-most edge of the tab bar separator.
    width_excess = 0.0f;
    for (int n = 0; n < count; n++)
    {
        float width_rounded = ImFloor(items[n].Width);
        width_excess += items[n].Width - width_rounded;
        items[n].Width = width_rounded;
    }
    if (width_excess > 0.0f)
        for (int n = 0; n < count; n++)
            if (items[n].Index < cast(int)(width_excess + 0.01f))
                items[n].Width += 1.0f;
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: ComboBox
//-------------------------------------------------------------------------
// - CalcMaxPopupHeightFromItemCount() [Internal]
// - BeginCombo()
// - BeginComboPopup() [Internal]
// - EndCombo()
// - BeginComboPreview() [Internal]
// - EndComboPreview() [Internal]
// - Combo()
//-------------------------------------------------------------------------

float CalcMaxPopupHeightFromItemCount(int items_count)
{
    ImGuiContext* g = GImGui;
    if (items_count <= 0)
        return FLT_MAX;
    return (g.FontSize + g.Style.ItemSpacing.y) * items_count - g.Style.ItemSpacing.y + (g.Style.WindowPadding.y * 2);
}

bool BeginCombo(string label, string preview_value, ImGuiComboFlags flags = ImGuiComboFlags.None)
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = GetCurrentWindow();

    ImGuiNextWindowDataFlags backup_next_window_data_flags = g.NextWindowData.Flags;
    g.NextWindowData.ClearFlags(); // We behave like Begin() and need to consume those values
    if (window.SkipItems)
        return false;

    const ImGuiStyle* style = &g.Style;
    const ImGuiID id = window.GetID(label);
    IM_ASSERT((flags & (ImGuiComboFlags.NoArrowButton | ImGuiComboFlags.NoPreview)) != (ImGuiComboFlags.NoArrowButton | ImGuiComboFlags.NoPreview)); // Can't use both flags together

    const float arrow_size = (flags & ImGuiComboFlags.NoArrowButton) ? 0.0f : GetFrameHeight();
    const ImVec2 label_size = CalcTextSize(label, true);
    const float w = (flags & ImGuiComboFlags.NoPreview) ? arrow_size : CalcItemWidth();
    const ImRect bb = ImRect(window.DC.CursorPos, window.DC.CursorPos + ImVec2(w, label_size.y + style.FramePadding.y * 2.0f));
    const ImRect total_bb = ImRect(bb.Min, bb.Max + ImVec2(label_size.x > 0.0f ? style.ItemInnerSpacing.x + label_size.x : 0.0f, 0.0f));
    ItemSize(total_bb, style.FramePadding.y);
    if (!ItemAdd(total_bb, id, &bb))
        return false;

    // Open on click
    bool hovered, held;
    bool pressed = ButtonBehavior(bb, id, &hovered, &held);
    const ImGuiID popup_id = ImHashStr("##ComboPopup", id);
    bool popup_open = IsPopupOpen(popup_id, ImGuiPopupFlags.None);
    if ((pressed || g.NavActivateId == id) && !popup_open)
    {
        OpenPopupEx(popup_id, ImGuiPopupFlags.None);
        popup_open = true;
    }

    // Render shape
    const ImU32 frame_col = GetColorU32(hovered ? ImGuiCol.FrameBgHovered : ImGuiCol.FrameBg);
    const float value_x2 = ImMax(bb.Min.x, bb.Max.x - arrow_size);
    RenderNavHighlight(bb, id);
    if (!(flags & ImGuiComboFlags.NoPreview))
        window.DrawList.AddRectFilled(bb.Min, ImVec2(value_x2, bb.Max.y), frame_col, style.FrameRounding, (flags & ImGuiComboFlags.NoArrowButton) ? ImDrawFlags.RoundCornersAll : ImDrawFlags.RoundCornersLeft);
    if (!(flags & ImGuiComboFlags.NoArrowButton))
    {
        ImU32 bg_col = GetColorU32((popup_open || hovered) ? ImGuiCol.ButtonHovered : ImGuiCol.Button);
        ImU32 text_col = GetColorU32(ImGuiCol.Text);
        window.DrawList.AddRectFilled(ImVec2(value_x2, bb.Min.y), bb.Max, bg_col, style.FrameRounding, (w <= arrow_size) ? ImDrawFlags.RoundCornersAll : ImDrawFlags.RoundCornersRight);
        if (value_x2 + arrow_size - style.FramePadding.x <= bb.Max.x)
            RenderArrow(window.DrawList, ImVec2(value_x2 + style.FramePadding.y, bb.Min.y + style.FramePadding.y), text_col, ImGuiDir.Down, 1.0f);
    }
    RenderFrameBorder(bb.Min, bb.Max, style.FrameRounding);

    // Custom preview
    if (flags & ImGuiComboFlags.CustomPreview)
    {
        g.ComboPreviewData.PreviewRect = ImRect(bb.Min.x, bb.Min.y, value_x2, bb.Max.y);
        IM_ASSERT(preview_value == NULL || preview_value[0] == 0);
        preview_value = NULL;
    }

    // Render preview and label
    if (preview_value != NULL && !(flags & ImGuiComboFlags.NoPreview))
    {
        if (g.LogEnabled)
            LogSetNextTextDecoration("{", "}");
        RenderTextClipped(bb.Min + style.FramePadding, ImVec2(value_x2, bb.Max.y), preview_value, NULL);
    }
    if (label_size.x > 0)
        RenderText(ImVec2(bb.Max.x + style.ItemInnerSpacing.x, bb.Min.y + style.FramePadding.y), label);

    if (!popup_open)
        return false;

    g.NextWindowData.Flags = backup_next_window_data_flags;
    return BeginComboPopup(popup_id, bb, flags);
}

bool BeginComboPopup(ImGuiID popup_id, const ImRect/*&*/ bb, ImGuiComboFlags flags)
{
    ImGuiContext* g = GImGui;
    if (!IsPopupOpen(popup_id, ImGuiPopupFlags.None))
    {
        g.NextWindowData.ClearFlags();
        return false;
    }

    // Set popup size
    float w = bb.GetWidth();
    if (g.NextWindowData.Flags & ImGuiNextWindowDataFlags.HasSizeConstraint)
    {
        g.NextWindowData.SizeConstraintRect.Min.x = ImMax(g.NextWindowData.SizeConstraintRect.Min.x, w);
    }
    else
    {
        if ((flags & ImGuiComboFlags.HeightMask_) == 0)
            flags |= ImGuiComboFlags.HeightRegular;
        IM_ASSERT(ImIsPowerOfTwo(flags & ImGuiComboFlags.HeightMask_)); // Only one
        int popup_max_height_in_items = -1;
        if (flags & ImGuiComboFlags.HeightRegular)     popup_max_height_in_items = 8;
        else if (flags & ImGuiComboFlags.HeightSmall)  popup_max_height_in_items = 4;
        else if (flags & ImGuiComboFlags.HeightLarge)  popup_max_height_in_items = 20;
        SetNextWindowSizeConstraints(ImVec2(w, 0.0f), ImVec2(FLT_MAX, CalcMaxPopupHeightFromItemCount(popup_max_height_in_items)));
    }

    // This is essentially a specialized version of BeginPopupEx()
    char[16] name;
    int length = ImFormatString(name, "##Combo_%02d", g.BeginPopupStack.Size); // Recycle windows based on depth

    // Set position given a custom constraint (peak into expected window size so we can position it)
    // FIXME: This might be easier to express with an hypothetical SetNextWindowPosConstraints() function?
    // FIXME: This might be moved to Begin() or at least around the same spot where Tooltips and other Popups are calling FindBestWindowPosForPopupEx()?
    if (ImGuiWindow* popup_window = FindWindowByName(cast(string)name[0..length]))
        if (popup_window.WasActive)
        {
            // Always override 'AutoPosLastDirection' to not leave a chance for a past value to affect us.
            ImVec2 size_expected = CalcWindowNextAutoFitSize(popup_window);
            popup_window.AutoPosLastDirection = (flags & ImGuiComboFlags.PopupAlignLeft) ? ImGuiDir.Left : ImGuiDir.Down; // Left = "Below, Toward Left", Down = "Below, Toward Right (default)"
            ImRect r_outer = GetPopupAllowedExtentRect(popup_window);
            ImVec2 pos = FindBestWindowPosForPopupEx(bb.GetBL(), size_expected, &popup_window.AutoPosLastDirection, r_outer, bb, ImGuiPopupPositionPolicy.ComboBox);
            SetNextWindowPos(pos);
        }

    // We don't use BeginPopupEx() solely because we have a custom name string, which we could make an argument to BeginPopupEx()
    ImGuiWindowFlags window_flags = ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.Popup | ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.NoResize | ImGuiWindowFlags.NoSavedSettings | ImGuiWindowFlags.NoMove;
    PushStyleVar(ImGuiStyleVar.WindowPadding, ImVec2(g.Style.FramePadding.x, g.Style.WindowPadding.y)); // Horizontally align ourselves with the framed text
    bool ret = Begin(cast(string)name[0..length], NULL, window_flags);
    PopStyleVar();
    if (!ret)
    {
        EndPopup();
        IM_ASSERT(0);   // This should never happen as we tested for IsPopupOpen() above
        return false;
    }
    return true;
}

void EndCombo()
{
    EndPopup();
}

// Call directly after the BeginCombo/EndCombo block. The preview is designed to only host non-interactive elements
// (Experimental, see GitHub issues: #1658, #4168)
bool BeginComboPreview()
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;
    ImGuiComboPreviewData* preview_data = &g.ComboPreviewData;

    if (window.SkipItems || !window.ClipRect.Overlaps(g.LastItemData.Rect)) // FIXME: Because we don't have a ImGuiItemStatusFlags_Visible flag to test last ItemAdd() result
        return false;
    IM_ASSERT(g.LastItemData.Rect.Min.x == preview_data.PreviewRect.Min.x && g.LastItemData.Rect.Min.y == preview_data.PreviewRect.Min.y); // Didn't call after BeginCombo/EndCombo block or forgot to pass ImGuiComboFlags_CustomPreview flag?
    if (!window.ClipRect.Contains(preview_data.PreviewRect)) // Narrower test (optional)
        return false;

    // FIXME: This could be contained in a PushWorkRect() api
    preview_data.BackupCursorPos = window.DC.CursorPos;
    preview_data.BackupCursorMaxPos = window.DC.CursorMaxPos;
    preview_data.BackupCursorPosPrevLine = window.DC.CursorPosPrevLine;
    preview_data.BackupPrevLineTextBaseOffset = window.DC.PrevLineTextBaseOffset;
    preview_data.BackupLayout = window.DC.LayoutType;
    window.DC.CursorPos = preview_data.PreviewRect.Min + g.Style.FramePadding;
    window.DC.CursorMaxPos = window.DC.CursorPos;
    window.DC.LayoutType = ImGuiLayoutType.Horizontal;
    PushClipRect(preview_data.PreviewRect.Min, preview_data.PreviewRect.Max, true);

    return true;
}

void EndComboPreview()
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;
    ImGuiComboPreviewData* preview_data = &g.ComboPreviewData;

    // FIXME: Using CursorMaxPos approximation instead of correct AABB which we will store in ImDrawCmd in the future
    ImDrawList* draw_list = window.DrawList;
    if (window.DC.CursorMaxPos.x < preview_data.PreviewRect.Max.x && window.DC.CursorMaxPos.y < preview_data.PreviewRect.Max.y)
        if (draw_list.CmdBuffer.Size > 1) // Unlikely case that the PushClipRect() didn't create a command
        {
            draw_list._CmdHeader.ClipRect = draw_list.CmdBuffer[draw_list.CmdBuffer.Size - 1].ClipRect = draw_list.CmdBuffer[draw_list.CmdBuffer.Size - 2].ClipRect;
            draw_list._TryMergeDrawCmds();
        }
    PopClipRect();
    window.DC.CursorPos = preview_data.BackupCursorPos;
    window.DC.CursorMaxPos = ImMax(window.DC.CursorMaxPos, preview_data.BackupCursorMaxPos);
    window.DC.CursorPosPrevLine = preview_data.BackupCursorPosPrevLine;
    window.DC.PrevLineTextBaseOffset = preview_data.BackupPrevLineTextBaseOffset;
    window.DC.LayoutType = preview_data.BackupLayout;
    preview_data.PreviewRect = ImRect();
}

// Getter for the old Combo() API: const char*[]
bool Items_ArrayGetter(void* data, int idx, string* out_text)
{
    string[] items = *cast(string[]*)data;
    if (out_text)
        *out_text = items[idx];
    return true;
}

// Getter for the old Combo() API: "item1\0item2\0item3\0"
bool Items_SingleStringGetter(void* data, int idx, string* out_text)
{
    // FIXME-OPT: we could pre-compute the indices to fasten this. But only 1 active combo means the waste is limited.
    string items_separated_by_zeros = *cast(string*)data;
    int items_count = 0;
    size_t index = 0;
    while (index < items_separated_by_zeros.length)
    {
        if (idx == items_count)
            break;
        index += strlen(items_separated_by_zeros[index..$]) + 1;
        items_count++;
    }
    if (index >= items_separated_by_zeros.length)
        return false;
    if (out_text)
        *out_text = ImCstring(items_separated_by_zeros[index..$]);
    return true;
}

// Old API, prefer using BeginCombo() nowadays if you can.
bool Combo(string label, int* current_item, bool function(void*, int, string*) nothrow @nogc items_getter, void* data, int items_count, int popup_max_height_in_items = -1)
{
    ImGuiContext* g = GImGui;

    // Call the getter to obtain the preview string which is a parameter to BeginCombo()
    string preview_value = NULL;
    if (*current_item >= 0 && *current_item < items_count)
        items_getter(data, *current_item, &preview_value);

    // The old Combo() API exposed "popup_max_height_in_items". The new more general BeginCombo() API doesn't have/need it, but we emulate it here.
    if (popup_max_height_in_items != -1 && !(g.NextWindowData.Flags & ImGuiNextWindowDataFlags.HasSizeConstraint))
        SetNextWindowSizeConstraints(ImVec2(0, 0), ImVec2(FLT_MAX, CalcMaxPopupHeightFromItemCount(popup_max_height_in_items)));

    if (!BeginCombo(label, preview_value, ImGuiComboFlags.None))
        return false;

    // Display items
    // FIXME-OPT: Use clipper (but we need to disable it on the appearing frame to make sure our call to SetItemDefaultFocus() is processed)
    bool value_changed = false;
    for (int i = 0; i < items_count; i++)
    {
        PushID(cast(void*)cast(intptr_t)i);
        const bool item_selected = (i == *current_item);
        string item_text;
        if (!items_getter(data, i, &item_text))
            item_text = "*Unknown item*";
        if (Selectable(item_text, item_selected))
        {
            value_changed = true;
            *current_item = i;
        }
        if (item_selected)
            SetItemDefaultFocus();
        PopID();
    }

    EndCombo();

    if (value_changed)
        MarkItemEdited(g.LastItemData.ID);

    return value_changed;
}

// Combo box helper allowing to pass an array of strings.
bool Combo(string label, int* current_item, string[] items, int height_in_items = -1)
{
    const bool value_changed = Combo(label, current_item, &Items_ArrayGetter, cast(void*)&items, cast(int)items.length, height_in_items);
    return value_changed;
}

// Combo box helper allowing to pass all items in a single string literal holding multiple zero-terminated items "item1\0item2\0"
bool Combo(string label, int* current_item, string items_separated_by_zeros, int height_in_items = -1)
{
    int items_count = 0;
    size_t index = 0;       // FIXME-OPT: Avoid computing this, or at least only when combo is open
    while (index < items_separated_by_zeros.length)
    {
        index += strlen(items_separated_by_zeros[index..$]) + 1;
        items_count++;
    }
    string[] result = (&items_separated_by_zeros)[0..items_count];
    bool value_changed = Combo(label, current_item, &Items_SingleStringGetter, cast(void*)&items_separated_by_zeros, items_count, height_in_items);
    return value_changed;
}

//-------------------------------------------------------------------------
// [SECTION] Data Type and Data Formatting Helpers [Internal]
//-------------------------------------------------------------------------
// - PatchFormatStringFloatToInt()
// - DataTypeGetInfo()
// - DataTypeFormatString()
// - DataTypeApplyOp()
// - DataTypeApplyOpFromText()
// - DataTypeClamp()
// - GetMinimumStepAtDecimalPrecision
// - RoundScalarWithFormat<>()
//-------------------------------------------------------------------------

__gshared const ImGuiDataTypeInfo[ImGuiDataType.COUNT] GDataTypeInfo =
[
    { sizeof!(byte),             "S8",   "%d",   "%d"    },  // ImGuiDataType_S8
    { sizeof!(ubyte),    "U8",   "%u",   "%u"    },
    { sizeof!(short),            "S16",  "%d",   "%d"    },  // ImGuiDataType_S16
    { sizeof!(ushort),   "U16",  "%u",   "%u"    },
    { sizeof!(int),              "S32",  "%d",   "%d"    },  // ImGuiDataType_S32
    { sizeof!(uint),     "U32",  "%u",   "%u"    },
    { sizeof!(ImS64),            "S64",  "%lld", "%lld"  },  // ImGuiDataType_S64
    { sizeof!(ImU64),            "U64",  "%llu", "%llu"  },
    { sizeof!(float),            "float", "%.3f",  "%f"    },  // ImGuiDataType_Float (float are promoted to double in va_arg)
    { sizeof!(double),           "double","%lf",  "%lf"  },  // ImGuiDataType_Double
];

// FIXME-LEGACY: Prior to 1.61 our DragInt() function internally used floats and because of this the compile-time default value for format was "%.0f".
// Even though we changed the compile-time default, we expect users to have carried %f around, which would break the display of DragInt() calls.
// To honor backward compatibility we are rewriting the format string, unless IMGUI_DISABLE_OBSOLETE_FUNCTIONS is enabled. What could possibly go wrong?!
string PatchFormatStringFloatToInt(string fmt)
{
    if (fmt == "%.0f") // Fast legacy path for "%.0f" which is expected to be the most common case.
        return "%d";
    size_t fmt_start = ImParseFormatFindStart(fmt);    // Find % (if any, and ignore %%)
    size_t fmt_end = ImParseFormatFindEnd(fmt, fmt_start);  // Find end of format specifier, which itself is an exercise of confidence/recklessness (because snprintf is dependent on libc or user).
    if (fmt_end > fmt_start && fmt[fmt_end-1] == 'f')
    {
static if (!IMGUI_DISABLE_OBSOLETE_FUNCTIONS) {
        if (fmt_start == 0 && fmt_end == fmt.length)
            return "%d";
        ImGuiContext* g = GImGui;
        int length = ImFormatString(g.TempBuffer, "%.*s%%d%s", cast(int)(fmt_start), fmt, fmt[fmt_end..$]); // Honor leading and trailing decorations, but lose alignment/precision.
        return cast(string)g.TempBuffer[0..length];
} else {
        IM_ASSERT(0, "DragInt(): Invalid format string!"); // Old versions used a default parameter of "%.0f", please replace with e.g. "%d"
}
    }
    return fmt;
}

const (ImGuiDataTypeInfo)* DataTypeGetInfo(ImGuiDataType data_type)
{
    IM_ASSERT(data_type >= 0 && data_type < ImGuiDataType.COUNT);
    return &GDataTypeInfo[data_type];
}

int DataTypeFormatString(char[] buf, ImGuiDataType data_type, const void* p_data, string format)
{
    // Signedness doesn't matter when pushing integer arguments
    // D_IMGUI: In D it does matter!
    if (data_type == ImGuiDataType.S32)
        return ImFormatString(buf, format, *cast(const ImS32*)p_data);
    if (data_type == ImGuiDataType.U32)
        return ImFormatString(buf, format, *cast(const ImU32*)p_data);
    if (data_type == ImGuiDataType.S64)
        return ImFormatString(buf, format, *cast(const ImS64*)p_data);
    if (data_type == ImGuiDataType.U64)
        return ImFormatString(buf, format, *cast(const ImU64*)p_data);
    if (data_type == ImGuiDataType.Float)
        return ImFormatString(buf, format, *cast(const float*)p_data);
    if (data_type == ImGuiDataType.Double)
        return ImFormatString(buf, format, *cast(const double*)p_data);
    if (data_type == ImGuiDataType.S8)
        return ImFormatString(buf, format, *cast(const ImS8*)p_data);
    if (data_type == ImGuiDataType.U8)
        return ImFormatString(buf, format, *cast(const ImU8*)p_data);
    if (data_type == ImGuiDataType.S16)
        return ImFormatString(buf, format, *cast(const ImS16*)p_data);
    if (data_type == ImGuiDataType.U16)
        return ImFormatString(buf, format, *cast(const ImU16*)p_data);
    IM_ASSERT(0);
    return 0;
}

void DataTypeApplyOp(ImGuiDataType data_type, int op, void* output, const void* arg1, const void* arg2)
{
    IM_ASSERT(op == '+' || op == '-');
    switch (data_type)
    {
        case ImGuiDataType.S8:
            if (op == '+') { *cast(ImS8*)output  = ImAddClampOverflow(*cast(const ImS8*)arg1,  *cast(const ImS8*)arg2,  IM_S8_MIN,  IM_S8_MAX); }
            if (op == '-') { *cast(ImS8*)output  = ImSubClampOverflow(*cast(const ImS8*)arg1,  *cast(const ImS8*)arg2,  IM_S8_MIN,  IM_S8_MAX); }
            return;
        case ImGuiDataType.U8:
            if (op == '+') { *cast(ImU8*)output  = ImAddClampOverflow(*cast(const ImU8*)arg1,  *cast(const ImU8*)arg2,  IM_U8_MIN,  IM_U8_MAX); }
            if (op == '-') { *cast(ImU8*)output  = ImSubClampOverflow(*cast(const ImU8*)arg1,  *cast(const ImU8*)arg2,  IM_U8_MIN,  IM_U8_MAX); }
            return;
        case ImGuiDataType.S16:
            if (op == '+') { *cast(ImS16*)output = ImAddClampOverflow(*cast(const ImS16*)arg1, *cast(const ImS16*)arg2, IM_S16_MIN, IM_S16_MAX); }
            if (op == '-') { *cast(ImS16*)output = ImSubClampOverflow(*cast(const ImS16*)arg1, *cast(const ImS16*)arg2, IM_S16_MIN, IM_S16_MAX); }
            return;
        case ImGuiDataType.U16:
            if (op == '+') { *cast(ImU16*)output = ImAddClampOverflow(*cast(const ImU16*)arg1, *cast(const ImU16*)arg2, IM_U16_MIN, IM_U16_MAX); }
            if (op == '-') { *cast(ImU16*)output = ImSubClampOverflow(*cast(const ImU16*)arg1, *cast(const ImU16*)arg2, IM_U16_MIN, IM_U16_MAX); }
            return;
        case ImGuiDataType.S32:
            if (op == '+') { *cast(ImS32*)output = ImAddClampOverflow(*cast(const ImS32*)arg1, *cast(const ImS32*)arg2, IM_S32_MIN, IM_S32_MAX); }
            if (op == '-') { *cast(ImS32*)output = ImSubClampOverflow(*cast(const ImS32*)arg1, *cast(const ImS32*)arg2, IM_S32_MIN, IM_S32_MAX); }
            return;
        case ImGuiDataType.U32:
            if (op == '+') { *cast(ImU32*)output = ImAddClampOverflow(*cast(const ImU32*)arg1, *cast(const ImU32*)arg2, IM_U32_MIN, IM_U32_MAX); }
            if (op == '-') { *cast(ImU32*)output = ImSubClampOverflow(*cast(const ImU32*)arg1, *cast(const ImU32*)arg2, IM_U32_MIN, IM_U32_MAX); }
            return;
        case ImGuiDataType.S64:
            if (op == '+') { *cast(ImS64*)output = ImAddClampOverflow(*cast(const ImS64*)arg1, *cast(const ImS64*)arg2, IM_S64_MIN, IM_S64_MAX); }
            if (op == '-') { *cast(ImS64*)output = ImSubClampOverflow(*cast(const ImS64*)arg1, *cast(const ImS64*)arg2, IM_S64_MIN, IM_S64_MAX); }
            return;
        case ImGuiDataType.U64:
            if (op == '+') { *cast(ImU64*)output = ImAddClampOverflow(*cast(const ImU64*)arg1, *cast(const ImU64*)arg2, IM_U64_MIN, IM_U64_MAX); }
            if (op == '-') { *cast(ImU64*)output = ImSubClampOverflow(*cast(const ImU64*)arg1, *cast(const ImU64*)arg2, IM_U64_MIN, IM_U64_MAX); }
            return;
        case ImGuiDataType.Float:
            if (op == '+') { *cast(float*)output = *cast(const float*)arg1 + *cast(const float*)arg2; }
            if (op == '-') { *cast(float*)output = *cast(const float*)arg1 - *cast(const float*)arg2; }
            return;
        case ImGuiDataType.Double:
            if (op == '+') { *cast(double*)output = *cast(const double*)arg1 + *cast(const double*)arg2; }
            if (op == '-') { *cast(double*)output = *cast(const double*)arg1 - *cast(const double*)arg2; }
            return;
        case ImGuiDataType.COUNT: break;
        default: break;
    }
    IM_ASSERT(0);
}

// User can input math operators (e.g. +100) to edit a numerical values.
// NB: This is _not_ a full expression evaluator. We should probably add one and replace this dumb mess..
bool DataTypeApplyOpFromText(string buf, string initial_value_buf, ImGuiDataType data_type, void* p_data, string format)
{
    while (buf.length > 0 && ImCharIsBlankA(buf[0]))
        buf = buf[1..$];
    if (buf.length == 0)
        return false;

    // We don't support '-' op because it would conflict with inputing negative value.
    // Instead you can use +-100 to subtract from an existing value
    char op = buf[0];
    if (op == '+' || op == '*' || op == '/')
    {
        buf = buf[1..$];
        while (buf.length > 0 && ImCharIsBlankA(buf[0]))
            buf = buf[1..$];
    }
    else
    {
        op = 0;
    }
    if (buf.length == 0)
        return false;

    // Copy the value in an opaque buffer so we can compare at the end of the function if it changed at all.
    const ImGuiDataTypeInfo* type_info = DataTypeGetInfo(data_type);
    ImGuiDataTypeTempStorage data_backup;
    memcpy(&data_backup, p_data, type_info.Size);

    if (format == NULL)
        format = type_info.ScanFmt;

    // FIXME-LEGACY: The aim is to remove those operators and write a proper expression evaluator at some point..
    int arg1i = 0;
    if (data_type == ImGuiDataType.S32)
    {
        int* v = cast(int*)p_data;
        int arg0i = *v;
        float arg1f = 0.0f;
        if (op && sscanf(initial_value_buf, format, &arg0i) < 1)
            return false;
        // Store operand in a float so we can use fractional value for multipliers (*1.1), but constant always parsed as integer so we can fit big integers (e.g. 2000000003) past float precision
        if (op == '+')      { if (sscanf(buf, "%d", &arg1i)) *v = cast(int)(arg0i + arg1i); }                   // Add (use "+-" to subtract)
        else if (op == '*') { if (sscanf(buf, "%f", &arg1f)) *v = cast(int)(arg0i * arg1f); }                   // Multiply
        else if (op == '/') { if (sscanf(buf, "%f", &arg1f) && arg1f != 0.0f) *v = cast(int)(arg0i / arg1f); }  // Divide
        else                { if (sscanf(buf, format, &arg1i) == 1) *v = arg1i; }                           // Assign constant
    }
    else if (data_type == ImGuiDataType.Float)
    {
        // For floats we have to ignore format with precision (e.g. "%.2f") because sscanf doesn't take them in
        format = "%f";
        float* v = cast(float*)p_data;
        float arg0f = *v, arg1f = 0.0f;
        if (op && sscanf(initial_value_buf, format, &arg0f) < 1)
            return false;
        if (sscanf(buf, format, &arg1f) < 1)
            return false;
        if (op == '+')      { *v = arg0f + arg1f; }                    // Add (use "+-" to subtract)
        else if (op == '*') { *v = arg0f * arg1f; }                    // Multiply
        else if (op == '/') { if (arg1f != 0.0f) *v = arg0f / arg1f; } // Divide
        else                { *v = arg1f; }                            // Assign constant
    }
    else if (data_type == ImGuiDataType.Double)
    {
        format = "%lf"; // scanf differentiate float/double unlike printf which forces everything to double because of ellipsis
        double* v = cast(double*)p_data;
        double arg0f = *v, arg1f = 0.0;
        if (op && sscanf(initial_value_buf, format, &arg0f) < 1)
            return false;
        if (sscanf(buf, format, &arg1f) < 1)
            return false;
        if (op == '+')      { *v = arg0f + arg1f; }                    // Add (use "+-" to subtract)
        else if (op == '*') { *v = arg0f * arg1f; }                    // Multiply
        else if (op == '/') { if (arg1f != 0.0f) *v = arg0f / arg1f; } // Divide
        else                { *v = arg1f; }                            // Assign constant
    }
    else if (data_type == ImGuiDataType.U32 || data_type == ImGuiDataType.S64 || data_type == ImGuiDataType.U64)
    {
        // All other types assign constant
        // We don't bother handling support for legacy operators since they are a little too crappy. Instead we will later implement a proper expression evaluator in the future.
        if (sscanf(buf, format, p_data) < 1)
            return false;
    }
    else
    {
        // Small types need a 32-bit buffer to receive the result from scanf()
        int v32;
        if (sscanf(buf, format, &v32) < 1)
            return false;
        if (data_type == ImGuiDataType.S8)
            *cast(ImS8*)p_data = cast(ImS8)ImClamp(v32, cast(int)IM_S8_MIN, cast(int)IM_S8_MAX);
        else if (data_type == ImGuiDataType.U8)
            *cast(ImU8*)p_data = cast(ImU8)ImClamp(v32, cast(int)IM_U8_MIN, cast(int)IM_U8_MAX);
        else if (data_type == ImGuiDataType.S16)
            *cast(ImS16*)p_data = cast(ImS16)ImClamp(v32, cast(int)IM_S16_MIN, cast(int)IM_S16_MAX);
        else if (data_type == ImGuiDataType.U16)
            *cast(ImU16*)p_data = cast(ImU16)ImClamp(v32, cast(int)IM_U16_MIN, cast(int)IM_U16_MAX);
        else
            IM_ASSERT(0);
    }

    return memcmp(&data_backup, p_data, type_info.Size) != 0;
}

int DataTypeCompareT(T)(const T* lhs, const T* rhs)
{
    if (*lhs < *rhs) return -1;
    if (*lhs > *rhs) return +1;
    return 0;
}

int DataTypeCompare(ImGuiDataType data_type, const void* arg_1, const void* arg_2)
{
    switch (data_type)
    {
    case ImGuiDataType.S8:     return DataTypeCompareT!(ImS8  )(cast(const ImS8*  )arg_1, cast(const ImS8*  )arg_2);
    case ImGuiDataType.U8:     return DataTypeCompareT!(ImU8  )(cast(const ImU8*  )arg_1, cast(const ImU8*  )arg_2);
    case ImGuiDataType.S16:    return DataTypeCompareT!(ImS16 )(cast(const ImS16* )arg_1, cast(const ImS16* )arg_2);
    case ImGuiDataType.U16:    return DataTypeCompareT!(ImU16 )(cast(const ImU16* )arg_1, cast(const ImU16* )arg_2);
    case ImGuiDataType.S32:    return DataTypeCompareT!(ImS32 )(cast(const ImS32* )arg_1, cast(const ImS32* )arg_2);
    case ImGuiDataType.U32:    return DataTypeCompareT!(ImU32 )(cast(const ImU32* )arg_1, cast(const ImU32* )arg_2);
    case ImGuiDataType.S64:    return DataTypeCompareT!(ImS64 )(cast(const ImS64* )arg_1, cast(const ImS64* )arg_2);
    case ImGuiDataType.U64:    return DataTypeCompareT!(ImU64 )(cast(const ImU64* )arg_1, cast(const ImU64* )arg_2);
    case ImGuiDataType.Float:  return DataTypeCompareT!(float )(cast(const float* )arg_1, cast(const float* )arg_2);
    case ImGuiDataType.Double: return DataTypeCompareT!(double)(cast(const double*)arg_1, cast(const double*)arg_2);
    case ImGuiDataType.COUNT:  break;
    default: break;
    }
    IM_ASSERT(0);
    return 0;
}

bool DataTypeClampT(T)(T* v, const T* v_min, const T* v_max)
{
    // Clamp, both sides are optional, return true if modified
    if (v_min && *v < *v_min) { *v = *v_min; return true; }
    if (v_max && *v > *v_max) { *v = *v_max; return true; }
    return false;
}

bool DataTypeClamp(ImGuiDataType data_type, void* p_data, const void* p_min, const void* p_max)
{
    switch (data_type)
    {
    case ImGuiDataType.S8:     return DataTypeClampT!(ImS8  )(cast(ImS8*  )p_data, cast(const ImS8*  )p_min, cast(const ImS8*  )p_max);
    case ImGuiDataType.U8:     return DataTypeClampT!(ImU8  )(cast(ImU8*  )p_data, cast(const ImU8*  )p_min, cast(const ImU8*  )p_max);
    case ImGuiDataType.S16:    return DataTypeClampT!(ImS16 )(cast(ImS16* )p_data, cast(const ImS16* )p_min, cast(const ImS16* )p_max);
    case ImGuiDataType.U16:    return DataTypeClampT!(ImU16 )(cast(ImU16* )p_data, cast(const ImU16* )p_min, cast(const ImU16* )p_max);
    case ImGuiDataType.S32:    return DataTypeClampT!(ImS32 )(cast(ImS32* )p_data, cast(const ImS32* )p_min, cast(const ImS32* )p_max);
    case ImGuiDataType.U32:    return DataTypeClampT!(ImU32 )(cast(ImU32* )p_data, cast(const ImU32* )p_min, cast(const ImU32* )p_max);
    case ImGuiDataType.S64:    return DataTypeClampT!(ImS64 )(cast(ImS64* )p_data, cast(const ImS64* )p_min, cast(const ImS64* )p_max);
    case ImGuiDataType.U64:    return DataTypeClampT!(ImU64 )(cast(ImU64* )p_data, cast(const ImU64* )p_min, cast(const ImU64* )p_max);
    case ImGuiDataType.Float:  return DataTypeClampT!(float )(cast(float* )p_data, cast(const float* )p_min, cast(const float* )p_max);
    case ImGuiDataType.Double: return DataTypeClampT!(double)(cast(double*)p_data, cast(const double*)p_min, cast(const double*)p_max);
    case ImGuiDataType.COUNT:  break;
    default: break;
    }
    IM_ASSERT(0);
    return false;
}

float GetMinimumStepAtDecimalPrecision(int decimal_precision)
{
    __gshared const float[10] min_steps = [ 1.0f, 0.1f, 0.01f, 0.001f, 0.0001f, 0.00001f, 0.000001f, 0.0000001f, 0.00000001f, 0.000000001f ];
    if (decimal_precision < 0)
        return FLT_MIN;
    return (decimal_precision < IM_ARRAYSIZE(min_steps)) ? min_steps[decimal_precision] : ImPow(10.0f, cast(float)-decimal_precision);
}

string ImAtoi(TYPE)(string src, TYPE* output)
{
    int negative = 0;
    size_t index = 0;
    if (index < src.length && src[index] == '-') { negative = 1; index++; }
    if (index < src.length && src[index] == '+') { index++; }
    TYPE v = 0;
    while (index < src.length && src[index] >= '0' && src[index] <= '9')
        v = (v * 10) + (src[index++] - '0');
    *output = negative ? -v : v;
    return src[index..$];
}

// Sanitize format
// - Zero terminate so extra characters after format (e.g. "%f123") don't confuse atof/atoi
// - stb_sprintf.h supports several new modifiers which format numbers in a way that also makes them incompatible atof/atoi.
string SanitizeFormatString(string fmt, char[] fmt_out)
{
    // IM_UNUSED(fmt_out_size);
    size_t fmt_end = ImParseFormatFindEnd(fmt, 0);
    fmt = fmt[0..fmt_end];
    IM_ASSERT(cast(size_t)(fmt.length) < fmt_out.length); // Format is too long, let us know if this happens to you!
    size_t fmt_out_index = 0;
    for (size_t index = 0; index < fmt.length; index++)
    {
        char c = fmt[index];
        if (c != '\'' && c != '$' && c != '_') // Custom flags provided by stb_sprintf.h. POSIX 2008 also supports '.
            fmt_out[fmt_out_index++] = c;
    }
    // *fmt_out = 0; // Zero-terminate
    return cast(string)fmt_out[0..fmt_out_index];
}

TYPE RoundScalarWithFormatT(TYPE, SIGNEDTYPE)(string format, ImGuiDataType data_type, TYPE v)
{
    format = ImParseFormatTrimDecorations(format);
    if (1 >= format.length || format[0] != '%' || (2 <= format.length && format[1] == '%')) // Don't apply if the value is not visible in the format string
        return v;

    // Sanitize format
    char[32] fmt_sanitized;
    format = SanitizeFormatString(format, fmt_sanitized);

    // Format value with our rounding, and read back
    char[64] v_str;
    int length = ImFormatString(v_str, format, v);
    string p = cast(string)v_str[0..length];
    while (p.length > 0 && p[0] == ' ')
        p = p[1..$];
    if (data_type == ImGuiDataType.Float || data_type == ImGuiDataType.Double)
        v = cast(TYPE)ImAtof(p);
    else
        ImAtoi(p, cast(SIGNEDTYPE*)&v);
    return v;
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: DragScalar, DragFloat, DragInt, etc.
//-------------------------------------------------------------------------
// - DragBehaviorT<>() [Internal]
// - DragBehavior() [Internal]
// - DragScalar()
// - DragScalarN()
// - DragFloat()
// - DragFloat2()
// - DragFloat3()
// - DragFloat4()
// - DragFloatRange2()
// - DragInt()
// - DragInt2()
// - DragInt3()
// - DragInt4()
// - DragIntRange2()
//-------------------------------------------------------------------------

// This is called by DragBehavior() when the widget is active (held by mouse or being manipulated with Nav controls)
bool DragBehaviorT(TYPE, SIGNEDTYPE, FLOATTYPE)(ImGuiDataType data_type, TYPE* v, float v_speed, TYPE v_min, TYPE v_max, string format, ImGuiSliderFlags flags)
{
    ImGuiContext* g = GImGui;
    const ImGuiAxis axis = (flags & ImGuiSliderFlags.Vertical) ? ImGuiAxis.Y : ImGuiAxis.X;
    const bool is_clamped = (v_min < v_max);
    const bool is_logarithmic = (flags & ImGuiSliderFlags.Logarithmic) != 0;
    const bool is_floating_point = (data_type == ImGuiDataType.Float) || (data_type == ImGuiDataType.Double);

    // Default tweak speed
    if (v_speed == 0.0f && is_clamped && (v_max - v_min < FLT_MAX))
        v_speed = cast(float)((v_max - v_min) * g.DragSpeedDefaultRatio);

    // Inputs accumulates into g.DragCurrentAccum, which is flushed into the current value as soon as it makes a difference with our precision settings
    float adjust_delta = 0.0f;
    if (g.ActiveIdSource == ImGuiInputSource.Mouse && IsMousePosValid() && IsMouseDragPastThreshold(ImGuiMouseButton.Left, g.IO.MouseDragThreshold * DRAG_MOUSE_THRESHOLD_FACTOR))
    {
        adjust_delta = g.IO.MouseDelta[axis];
        if (g.IO.KeyAlt)
            adjust_delta *= 1.0f / 100.0f;
        if (g.IO.KeyShift)
            adjust_delta *= 10.0f;
    }
    else if (g.ActiveIdSource == ImGuiInputSource.Nav)
    {
        const int decimal_precision = is_floating_point ? ImParseFormatPrecision(format, 3) : 0;
        adjust_delta = GetNavInputAmount2d(ImGuiNavDirSourceFlags.Keyboard | ImGuiNavDirSourceFlags.PadDPad, ImGuiInputReadMode.RepeatFast, 1.0f / 10.0f, 10.0f)[axis];
        v_speed = ImMax(v_speed, GetMinimumStepAtDecimalPrecision(decimal_precision));
    }
    adjust_delta *= v_speed;

    // For vertical drag we currently assume that Up=higher value (like we do with vertical sliders). This may become a parameter.
    if (axis == ImGuiAxis.Y)
        adjust_delta = -adjust_delta;

    // For logarithmic use our range is effectively 0..1 so scale the delta into that range
    if (is_logarithmic && (v_max - v_min < FLT_MAX) && ((v_max - v_min) > 0.000001f)) // Epsilon to avoid /0
        adjust_delta /= cast(float)(v_max - v_min);

    // Clear current value on activation
    // Avoid altering values and clamping when we are _already_ past the limits and heading in the same direction, so e.g. if range is 0..255, current value is 300 and we are pushing to the right side, keep the 300.
    bool is_just_activated = g.ActiveIdIsJustActivated;
    bool is_already_past_limits_and_pushing_outward = is_clamped && ((*v >= v_max && adjust_delta > 0.0f) || (*v <= v_min && adjust_delta < 0.0f));
    if (is_just_activated || is_already_past_limits_and_pushing_outward)
    {
        g.DragCurrentAccum = 0.0f;
        g.DragCurrentAccumDirty = false;
    }
    else if (adjust_delta != 0.0f)
    {
        g.DragCurrentAccum += adjust_delta;
        g.DragCurrentAccumDirty = true;
    }

    if (!g.DragCurrentAccumDirty)
        return false;

    TYPE v_cur = *v;
    FLOATTYPE v_old_ref_for_accum_remainder = cast(FLOATTYPE)0.0f;

    float logarithmic_zero_epsilon = 0.0f; // Only valid when is_logarithmic is true
    const float zero_deadzone_halfsize = 0.0f; // Drag widgets have no deadzone (as it doesn't make sense)
    if (is_logarithmic)
    {
        // When using logarithmic sliders, we need to clamp to avoid hitting zero, but our choice of clamp value greatly affects slider precision. We attempt to use the specified precision to estimate a good lower bound.
        const int decimal_precision = is_floating_point ? ImParseFormatPrecision(format, 3) : 1;
        logarithmic_zero_epsilon = ImPow(0.1f, cast(float)decimal_precision);

        // Convert to parametric space, apply delta, convert back
        float v_old_parametric = ScaleRatioFromValueT!(TYPE, SIGNEDTYPE, FLOATTYPE)(data_type, v_cur, v_min, v_max, is_logarithmic, logarithmic_zero_epsilon, zero_deadzone_halfsize);
        float v_new_parametric = v_old_parametric + g.DragCurrentAccum;
        v_cur = ScaleValueFromRatioT!(TYPE, SIGNEDTYPE, FLOATTYPE)(data_type, v_new_parametric, v_min, v_max, is_logarithmic, logarithmic_zero_epsilon, zero_deadzone_halfsize);
        v_old_ref_for_accum_remainder = v_old_parametric;
    }
    else
    {
        v_cur += cast(SIGNEDTYPE)g.DragCurrentAccum;
    }

    // Round to user desired precision based on format string
    if (!(flags & ImGuiSliderFlags.NoRoundToFormat))
        v_cur = RoundScalarWithFormatT!(TYPE, SIGNEDTYPE)(format, data_type, v_cur);

    // Preserve remainder after rounding has been applied. This also allow slow tweaking of values.
    g.DragCurrentAccumDirty = false;
    if (is_logarithmic)
    {
        // Convert to parametric space, apply delta, convert back
        float v_new_parametric = ScaleRatioFromValueT!(TYPE, SIGNEDTYPE, FLOATTYPE)(data_type, v_cur, v_min, v_max, is_logarithmic, logarithmic_zero_epsilon, zero_deadzone_halfsize);
        g.DragCurrentAccum -= cast(float)(v_new_parametric - v_old_ref_for_accum_remainder);
    }
    else
    {
        g.DragCurrentAccum -= cast(float)(cast(SIGNEDTYPE)v_cur - cast(SIGNEDTYPE)*v);
    }

    // Lose zero sign for float/double
    if (v_cur == cast(TYPE)-0)
        v_cur = cast(TYPE)0;

    // Clamp values (+ handle overflow/wrap-around for integer types)
    if (*v != v_cur && is_clamped)
    {
        if (v_cur < v_min || (v_cur > *v && adjust_delta < 0.0f && !is_floating_point))
            v_cur = v_min;
        if (v_cur > v_max || (v_cur < *v && adjust_delta > 0.0f && !is_floating_point))
            v_cur = v_max;
    }

    // Apply result
    if (*v == v_cur)
        return false;
    *v = v_cur;
    return true;
}

bool DragBehavior(ImGuiID id, ImGuiDataType data_type, void* p_v, float v_speed, const void* p_min, const void* p_max, string format, ImGuiSliderFlags flags)
{
    // Read imgui.cpp "API BREAKING CHANGES" section for 1.78 if you hit this assert.
    IM_ASSERT((flags == 1 || (flags & ImGuiSliderFlags.InvalidMask_) == 0), "Invalid ImGuiSliderFlags flags! Has the 'float power' argument been mistakenly cast to flags? Call function with ImGuiSliderFlags_Logarithmic flags instead.");

    ImGuiContext* g = GImGui;
    if (g.ActiveId == id)
    {
        if (g.ActiveIdSource == ImGuiInputSource.Mouse && !g.IO.MouseDown[0])
            ClearActiveID();
        else if (g.ActiveIdSource == ImGuiInputSource.Nav && g.NavActivatePressedId == id && !g.ActiveIdIsJustActivated)
            ClearActiveID();
    }
    if (g.ActiveId != id)
        return false;
    if ((g.LastItemData.InFlags & ImGuiItemFlags.ReadOnly) || (flags & ImGuiSliderFlags.ReadOnly))
        return false;

    switch (data_type)
    {
    case ImGuiDataType.S8:     { ImS32 v32 = cast(ImS32)*cast(ImS8*)p_v;  bool r = DragBehaviorT!(ImS32, ImS32, float)(ImGuiDataType.S32, &v32, v_speed, p_min ? *cast(const ImS8*) p_min : IM_S8_MIN,  p_max ? *cast(const ImS8*)p_max  : IM_S8_MAX,  format, flags); if (r) *cast(ImS8*)p_v = cast(ImS8)v32; return r; }
    case ImGuiDataType.U8:     { ImU32 v32 = cast(ImU32)*cast(ImU8*)p_v;  bool r = DragBehaviorT!(ImU32, ImS32, float)(ImGuiDataType.U32, &v32, v_speed, p_min ? *cast(const ImU8*) p_min : IM_U8_MIN,  p_max ? *cast(const ImU8*)p_max  : IM_U8_MAX,  format, flags); if (r) *cast(ImU8*)p_v = cast(ImU8)v32; return r; }
    case ImGuiDataType.S16:    { ImS32 v32 = cast(ImS32)*cast(ImS16*)p_v; bool r = DragBehaviorT!(ImS32, ImS32, float)(ImGuiDataType.S32, &v32, v_speed, p_min ? *cast(const ImS16*)p_min : IM_S16_MIN, p_max ? *cast(const ImS16*)p_max : IM_S16_MAX, format, flags); if (r) *cast(ImS16*)p_v = cast(ImS16)v32; return r; }
    case ImGuiDataType.U16:    { ImU32 v32 = cast(ImU32)*cast(ImU16*)p_v; bool r = DragBehaviorT!(ImU32, ImS32, float)(ImGuiDataType.U32, &v32, v_speed, p_min ? *cast(const ImU16*)p_min : IM_U16_MIN, p_max ? *cast(const ImU16*)p_max : IM_U16_MAX, format, flags); if (r) *cast(ImU16*)p_v = cast(ImU16)v32; return r; }
    case ImGuiDataType.S32:    return DragBehaviorT!(ImS32, ImS32, float )(data_type, cast(ImS32*)p_v,  v_speed, p_min ? *cast(const ImS32* )p_min : IM_S32_MIN, p_max ? *cast(const ImS32* )p_max : IM_S32_MAX, format, flags);
    case ImGuiDataType.U32:    return DragBehaviorT!(ImU32, ImS32, float )(data_type, cast(ImU32*)p_v,  v_speed, p_min ? *cast(const ImU32* )p_min : IM_U32_MIN, p_max ? *cast(const ImU32* )p_max : IM_U32_MAX, format, flags);
    case ImGuiDataType.S64:    return DragBehaviorT!(ImS64, ImS64, double)(data_type, cast(ImS64*)p_v,  v_speed, p_min ? *cast(const ImS64* )p_min : IM_S64_MIN, p_max ? *cast(const ImS64* )p_max : IM_S64_MAX, format, flags);
    case ImGuiDataType.U64:    return DragBehaviorT!(ImU64, ImS64, double)(data_type, cast(ImU64*)p_v,  v_speed, p_min ? *cast(const ImU64* )p_min : IM_U64_MIN, p_max ? *cast(const ImU64* )p_max : IM_U64_MAX, format, flags);
    case ImGuiDataType.Float:  return DragBehaviorT!(float, float, float )(data_type, cast(float*)p_v,  v_speed, p_min ? *cast(const float* )p_min : -FLT_MAX,   p_max ? *cast(const float* )p_max : FLT_MAX,    format, flags);
    case ImGuiDataType.Double: return DragBehaviorT!(double,double,double)(data_type, cast(double*)p_v, v_speed, p_min ? *cast(const double*)p_min : -DBL_MAX,   p_max ? *cast(const double*)p_max : DBL_MAX,    format, flags);
    case ImGuiDataType.COUNT:  break;
    default: break;
    }
    IM_ASSERT(0);
    return false;
}

// Note: p_data, p_min and p_max are _pointers_ to a memory address holding the data. For a Drag widget, p_min and p_max are optional.
// Read code of e.g. DragFloat(), DragInt() etc. or examples in 'Demo->Widgets->Data Types' to understand how to use this function directly.
bool DragScalar(string label, ImGuiDataType data_type, void* p_data, float v_speed, const void* p_min = NULL, const void* p_max = NULL, string format = NULL, ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    ImGuiContext* g = GImGui;
    const ImGuiStyle* style = &g.Style;
    const ImGuiID id = window.GetID(label);
    const float w = CalcItemWidth();

    const ImVec2 label_size = CalcTextSize(label, true);
    const ImRect frame_bb = ImRect(window.DC.CursorPos, window.DC.CursorPos + ImVec2(w, label_size.y + style.FramePadding.y * 2.0f));
    const ImRect total_bb = ImRect(frame_bb.Min, frame_bb.Max + ImVec2(label_size.x > 0.0f ? style.ItemInnerSpacing.x + label_size.x : 0.0f, 0.0f));

    const bool temp_input_allowed = (flags & ImGuiSliderFlags.NoInput) == 0;
    ItemSize(total_bb, style.FramePadding.y);
    if (!ItemAdd(total_bb, id, &frame_bb, temp_input_allowed ? ImGuiItemAddFlags.Focusable : ImGuiItemAddFlags.None))
        return false;

    // Default format string when passing NULL
    if (format == NULL)
        format = DataTypeGetInfo(data_type).PrintFmt;
    else if (data_type == ImGuiDataType.S32 && format != "%d") // (FIXME-LEGACY: Patch old "%.0f" format string to use "%d", read function more details.)
        format = PatchFormatStringFloatToInt(format);

    // Tabbing or CTRL-clicking on Drag turns it into an InputText
    const bool hovered = ItemHoverable(frame_bb, id);
    bool temp_input_is_active = temp_input_allowed && TempInputIsActive(id);
    if (!temp_input_is_active)
    {
        const bool focus_requested = temp_input_allowed && (g.LastItemData.StatusFlags & ImGuiItemStatusFlags.Focused) != 0;
        const bool clicked = (hovered && g.IO.MouseClicked[0]);
        const bool double_clicked = (hovered && g.IO.MouseDoubleClicked[0]);
        if (focus_requested || clicked || double_clicked || g.NavActivateId == id || g.NavInputId == id)
        {
            SetActiveID(id, window);
            SetFocusID(id, window);
            FocusWindow(window);
            g.ActiveIdUsingNavDirMask = (1 << ImGuiDir.Left) | (1 << ImGuiDir.Right);
            if (temp_input_allowed && (focus_requested || (clicked && g.IO.KeyCtrl) || double_clicked || g.NavInputId == id))
                temp_input_is_active = true;
        }
        // Experimental: simple click (without moving) turns Drag into an InputText
        // FIXME: Currently polling ImGuiConfigFlags_IsTouchScreen, may either poll an hypothetical ImGuiBackendFlags_HasKeyboard and/or an explicit drag settings.
        if (g.IO.ConfigDragClickToInputText && temp_input_allowed && !temp_input_is_active)
            if (g.ActiveId == id && hovered && g.IO.MouseReleased[0] && !IsMouseDragPastThreshold(ImGuiMouseButton.Left, g.IO.MouseDragThreshold * DRAG_MOUSE_THRESHOLD_FACTOR))
            {
                g.NavInputId = id;
                temp_input_is_active = true;
            }
    }

    if (temp_input_is_active)
    {
        // Only clamp CTRL+Click input when ImGuiSliderFlags_AlwaysClamp is set
        const bool is_clamp_input = (flags & ImGuiSliderFlags.AlwaysClamp) != 0 && (p_min == NULL || p_max == NULL || DataTypeCompare(data_type, p_min, p_max) < 0);
        return TempInputScalar(frame_bb, id, label, data_type, p_data, format, is_clamp_input ? p_min : NULL, is_clamp_input ? p_max : NULL);
    }

    // Draw frame
    const ImU32 frame_col = GetColorU32(g.ActiveId == id ? ImGuiCol.FrameBgActive : hovered ? ImGuiCol.FrameBgHovered : ImGuiCol.FrameBg);
    RenderNavHighlight(frame_bb, id);
    RenderFrame(frame_bb.Min, frame_bb.Max, frame_col, true, style.FrameRounding);

    // Drag behavior
    const bool value_changed = DragBehavior(id, data_type, p_data, v_speed, p_min, p_max, format, flags);
    if (value_changed)
        MarkItemEdited(id);

    // Display value using user-provided display format so user can add prefix/suffix/decorations to the value.
    char[64] value_buf;
    int value_buf_end = DataTypeFormatString(value_buf, data_type, p_data, format);
    if (g.LogEnabled)
        LogSetNextTextDecoration("{", "}");
    RenderTextClipped(frame_bb.Min, frame_bb.Max, cast(string)value_buf[0..value_buf_end], NULL, ImVec2(0.5f, 0.5f));

    if (label_size.x > 0.0f)
        RenderText(ImVec2(frame_bb.Max.x + style.ItemInnerSpacing.x, frame_bb.Min.y + style.FramePadding.y), label);

    IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags);
    return value_changed;
}

bool DragScalarN(string label, ImGuiDataType data_type, void* p_data, int components, float v_speed, const void* p_min = NULL, const void* p_max = NULL, string format = NULL, ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    ImGuiContext* g = GImGui;
    bool value_changed = false;
    BeginGroup();
    PushID(label);
    PushMultiItemsWidths(components, CalcItemWidth());
    size_t type_size = GDataTypeInfo[data_type].Size;
    for (int i = 0; i < components; i++)
    {
        PushID(i);
        if (i > 0)
            SameLine(0, g.Style.ItemInnerSpacing.x);
        value_changed |= DragScalar("", data_type, p_data, v_speed, p_min, p_max, format, flags);
        PopID();
        PopItemWidth();
        p_data = cast(void*)(cast(char*)p_data + type_size);
    }
    PopID();

    string label_end = FindRenderedTextEnd(label);
    if (label_end.length != 0)
    {
        SameLine(0, g.Style.ItemInnerSpacing.x);
        TextEx(label_end);
    }

    EndGroup();
    return value_changed;
}

bool DragFloat(string label, float* v, float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, string format = "%.3f", ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    return DragScalar(label, ImGuiDataType.Float, v, v_speed, &v_min, &v_max, format, flags);
}

bool DragFloat2(string label, float[/*2*/] v, float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, string format = "%.3f", ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    return DragScalarN(label, ImGuiDataType.Float, v.ptr, 2, v_speed, &v_min, &v_max, format, flags);
}

bool DragFloat3(string label, float[/*3*/] v, float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, string format = "%.3f", ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    return DragScalarN(label, ImGuiDataType.Float, v.ptr, 3, v_speed, &v_min, &v_max, format, flags);
}

bool DragFloat4(string label, float[/*4*/] v, float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, string format = "%.3f", ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    return DragScalarN(label, ImGuiDataType.Float, v.ptr, 4, v_speed, &v_min, &v_max, format, flags);
}

bool DragFloat2(string label, ImVec2* v, float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, string format = "%.3f", ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    return DragFloat2(label, (&v.x)[0..2], v_speed, v_min, v_max, format, flags);
}

// NB: You likely want to specify the ImGuiSliderFlags_AlwaysClamp when using this.
bool DragFloatRange2(string label, float* v_current_min, float* v_current_max, float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, string format = "%.3f", string format_max = NULL, ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    ImGuiContext* g = GImGui;
    PushID(label);
    BeginGroup();
    PushMultiItemsWidths(2, CalcItemWidth());

    float min_min = (v_min >= v_max) ? -FLT_MAX : v_min;
    float min_max = (v_min >= v_max) ? *v_current_max : ImMin(v_max, *v_current_max);
    ImGuiSliderFlags min_flags = flags | ((min_min == min_max) ? ImGuiSliderFlags.ReadOnly : ImGuiSliderFlags.None);
    bool value_changed = DragScalar("##min", ImGuiDataType.Float, v_current_min, v_speed, &min_min, &min_max, format, min_flags);
    PopItemWidth();
    SameLine(0, g.Style.ItemInnerSpacing.x);

    float max_min = (v_min >= v_max) ? *v_current_min : ImMax(v_min, *v_current_min);
    float max_max = (v_min >= v_max) ? FLT_MAX : v_max;
    ImGuiSliderFlags max_flags = flags | ((max_min == max_max) ? ImGuiSliderFlags.ReadOnly : ImGuiSliderFlags.None);
    value_changed |= DragScalar("##max", ImGuiDataType.Float, v_current_max, v_speed, &max_min, &max_max, format_max ? format_max : format, max_flags);
    PopItemWidth();
    SameLine(0, g.Style.ItemInnerSpacing.x);

    TextEx(FindRenderedTextEnd(label));
    EndGroup();
    PopID();

    return value_changed;
}

// NB: v_speed is float to allow adjusting the drag speed with more precision
bool DragInt(string label, int* v, float v_speed = 1.0f, int v_min = 0, int v_max = 0, string format = "%d", ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    return DragScalar(label, ImGuiDataType.S32, v, v_speed, &v_min, &v_max, format, flags);
}

bool DragInt2(string label, int[/*2*/] v, float v_speed = 1.0f, int v_min = 0, int v_max = 0, string format = "%d", ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    return DragScalarN(label, ImGuiDataType.S32, v.ptr, 2, v_speed, &v_min, &v_max, format, flags);
}

bool DragInt3(string label, int[/*3*/] v, float v_speed = 1.0f, int v_min = 0, int v_max = 0, string format = "%d", ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    return DragScalarN(label, ImGuiDataType.S32, v.ptr, 3, v_speed, &v_min, &v_max, format, flags);
}

bool DragInt4(string label, int[/*4*/] v, float v_speed = 1.0f, int v_min = 0, int v_max = 0, string format = "%d", ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    return DragScalarN(label, ImGuiDataType.S32, v.ptr, 4, v_speed, &v_min, &v_max, format, flags);
}

// NB: You likely want to specify the ImGuiSliderFlags_AlwaysClamp when using this.
bool DragIntRange2(string label, int* v_current_min, int* v_current_max, float v_speed = 1.0f, int v_min = 0, int v_max = 0, string format = "%d", string format_max = NULL, ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    ImGuiContext* g = GImGui;
    PushID(label);
    BeginGroup();
    PushMultiItemsWidths(2, CalcItemWidth());

    int min_min = (v_min >= v_max) ? INT_MIN : v_min;
    int min_max = (v_min >= v_max) ? *v_current_max : ImMin(v_max, *v_current_max);
    ImGuiSliderFlags min_flags = flags | ((min_min == min_max) ? ImGuiSliderFlags.ReadOnly : ImGuiSliderFlags.None);
    bool value_changed = DragInt("##min", v_current_min, v_speed, min_min, min_max, format, min_flags);
    PopItemWidth();
    SameLine(0, g.Style.ItemInnerSpacing.x);

    int max_min = (v_min >= v_max) ? *v_current_min : ImMax(v_min, *v_current_min);
    int max_max = (v_min >= v_max) ? INT_MAX : v_max;
    ImGuiSliderFlags max_flags = flags | ((max_min == max_max) ? ImGuiSliderFlags.ReadOnly : ImGuiSliderFlags.None);
    value_changed |= DragInt("##max", v_current_max, v_speed, max_min, max_max, format_max ? format_max : format, max_flags);
    PopItemWidth();
    SameLine(0, g.Style.ItemInnerSpacing.x);

    TextEx(FindRenderedTextEnd(label));
    EndGroup();
    PopID();

    return value_changed;
}

static if (!IMGUI_DISABLE_OBSOLETE_FUNCTIONS) {

// Obsolete versions with power parameter. See https://github.com/ocornut/imgui/issues/3361 for details.
bool DragScalar(string label, ImGuiDataType data_type, void* p_data, float v_speed, const void* p_min, const void* p_max, string format, float power)
{
    ImGuiSliderFlags drag_flags = ImGuiSliderFlags.None;
    if (power != 1.0f)
    {
        IM_ASSERT(power == 1.0f, "Call function with ImGuiSliderFlags_Logarithmic flags instead of using the old 'float power' function!");
        IM_ASSERT(p_min != NULL && p_max != NULL);  // When using a power curve the drag needs to have known bounds
        drag_flags |= ImGuiSliderFlags.Logarithmic;   // Fallback for non-asserting paths
    }
    return DragScalar(label, data_type, p_data, v_speed, p_min, p_max, format, drag_flags);
}

bool DragScalarN(string label, ImGuiDataType data_type, void* p_data, int components, float v_speed, const void* p_min, const void* p_max, string format, float power)
{
    ImGuiSliderFlags drag_flags = ImGuiSliderFlags.None;
    if (power != 1.0f)
    {
        IM_ASSERT(power == 1.0f, "Call function with ImGuiSliderFlags_Logarithmic flags instead of using the old 'float power' function!");
        IM_ASSERT(p_min != NULL && p_max != NULL);  // When using a power curve the drag needs to have known bounds
        drag_flags |= ImGuiSliderFlags.Logarithmic;   // Fallback for non-asserting paths
    }
    return DragScalarN(label, data_type, p_data, components, v_speed, p_min, p_max, format, drag_flags);
}

} // IMGUI_DISABLE_OBSOLETE_FUNCTIONS

//-------------------------------------------------------------------------
// [SECTION] Widgets: SliderScalar, SliderFloat, SliderInt, etc.
//-------------------------------------------------------------------------
// - ScaleRatioFromValueT<> [Internal]
// - ScaleValueFromRatioT<> [Internal]
// - SliderBehaviorT<>() [Internal]
// - SliderBehavior() [Internal]
// - SliderScalar()
// - SliderScalarN()
// - SliderFloat()
// - SliderFloat2()
// - SliderFloat3()
// - SliderFloat4()
// - SliderAngle()
// - SliderInt()
// - SliderInt2()
// - SliderInt3()
// - SliderInt4()
// - VSliderScalar()
// - VSliderFloat()
// - VSliderInt()
//-------------------------------------------------------------------------

// Convert a value v in the output space of a slider into a parametric position on the slider itself (the logical opposite of ScaleValueFromRatioT)
float ScaleRatioFromValueT(TYPE, SIGNEDTYPE, FLOATTYPE)(ImGuiDataType data_type, TYPE v, TYPE v_min, TYPE v_max, bool is_logarithmic, float logarithmic_zero_epsilon, float zero_deadzone_halfsize)
{
    if (v_min == v_max)
        return 0.0f;
    IM_UNUSED(data_type);

    const TYPE v_clamped = (v_min < v_max) ? ImClamp(v, v_min, v_max) : ImClamp(v, v_max, v_min);
    if (is_logarithmic)
    {
        bool flipped = v_max < v_min;

        if (flipped) // Handle the case where the range is backwards
            ImSwap(v_min, v_max);

        // Fudge min/max to avoid getting close to log(0)
        FLOATTYPE v_min_fudged = (ImAbs(cast(FLOATTYPE)v_min) < logarithmic_zero_epsilon) ? ((v_min < 0.0f) ? -logarithmic_zero_epsilon : logarithmic_zero_epsilon) : cast(FLOATTYPE)v_min;
        FLOATTYPE v_max_fudged = (ImAbs(cast(FLOATTYPE)v_max) < logarithmic_zero_epsilon) ? ((v_max < 0.0f) ? -logarithmic_zero_epsilon : logarithmic_zero_epsilon) : cast(FLOATTYPE)v_max;

        // Awkward special cases - we need ranges of the form (-100 .. 0) to convert to (-100 .. -epsilon), not (-100 .. epsilon)
        if ((v_min == 0.0f) && (v_max < 0.0f))
            v_min_fudged = -logarithmic_zero_epsilon;
        else if ((v_max == 0.0f) && (v_min < 0.0f))
            v_max_fudged = -logarithmic_zero_epsilon;

        float result;

        if (v_clamped <= v_min_fudged)
            result = 0.0f; // Workaround for values that are in-range but below our fudge
        else if (v_clamped >= v_max_fudged)
            result = 1.0f; // Workaround for values that are in-range but above our fudge
        else if ((v_min * v_max) < 0.0f) // Range crosses zero, so split into two portions
        {
            float zero_point_center = (-cast(float)v_min) / (cast(float)v_max - cast(float)v_min); // The zero point in parametric space.  There's an argument we should take the logarithmic nature into account when calculating this, but for now this should do (and the most common case of a symmetrical range works fine)
            float zero_point_snap_L = zero_point_center - zero_deadzone_halfsize;
            float zero_point_snap_R = zero_point_center + zero_deadzone_halfsize;
            if (v == 0.0f)
                result = zero_point_center; // Special case for exactly zero
            else if (v < 0.0f)
                result = (1.0f - cast(float)(ImLog(-cast(FLOATTYPE)v_clamped / logarithmic_zero_epsilon) / ImLog(-v_min_fudged / logarithmic_zero_epsilon))) * zero_point_snap_L;
            else
                result = zero_point_snap_R + (cast(float)(ImLog(cast(FLOATTYPE)v_clamped / logarithmic_zero_epsilon) / ImLog(v_max_fudged / logarithmic_zero_epsilon)) * (1.0f - zero_point_snap_R));
        }
        else if ((v_min < 0.0f) || (v_max < 0.0f)) // Entirely negative slider
            result = 1.0f - cast(float)(ImLog(-cast(FLOATTYPE)v_clamped / -v_max_fudged) / ImLog(-v_min_fudged / -v_max_fudged));
        else
            result = cast(float)(ImLog(cast(FLOATTYPE)v_clamped / v_min_fudged) / ImLog(v_max_fudged / v_min_fudged));

        return flipped ? (1.0f - result) : result;
    }

    // Linear slider
    return cast(float)(cast(FLOATTYPE)cast(SIGNEDTYPE)(v_clamped - v_min) / cast(FLOATTYPE)cast(SIGNEDTYPE)(v_max - v_min));
}

// Convert a parametric position on a slider into a value v in the output space (the logical opposite of ScaleRatioFromValueT)
TYPE ScaleValueFromRatioT(TYPE, SIGNEDTYPE, FLOATTYPE)(ImGuiDataType data_type, float t, TYPE v_min, TYPE v_max, bool is_logarithmic, float logarithmic_zero_epsilon, float zero_deadzone_halfsize)
{
    if (v_min == v_max)
        return v_min;
    const bool is_floating_point = (data_type == ImGuiDataType.Float) || (data_type == ImGuiDataType.Double);

    TYPE result;
    if (is_logarithmic)
    {
        // We special-case the extents because otherwise our fudging can lead to "mathematically correct" but non-intuitive behaviors like a fully-left slider not actually reaching the minimum value
        if (t <= 0.0f)
            result = v_min;
        else if (t >= 1.0f)
            result = v_max;
        else
        {
            bool flipped = v_max < v_min; // Check if range is "backwards"

            // Fudge min/max to avoid getting silly results close to zero
            FLOATTYPE v_min_fudged = (ImAbs(cast(FLOATTYPE)v_min) < logarithmic_zero_epsilon) ? ((v_min < 0.0f) ? -logarithmic_zero_epsilon : logarithmic_zero_epsilon) : cast(FLOATTYPE)v_min;
            FLOATTYPE v_max_fudged = (ImAbs(cast(FLOATTYPE)v_max) < logarithmic_zero_epsilon) ? ((v_max < 0.0f) ? -logarithmic_zero_epsilon : logarithmic_zero_epsilon) : cast(FLOATTYPE)v_max;

            if (flipped)
                ImSwap(v_min_fudged, v_max_fudged);

            // Awkward special case - we need ranges of the form (-100 .. 0) to convert to (-100 .. -epsilon), not (-100 .. epsilon)
            if ((v_max == 0.0f) && (v_min < 0.0f))
                v_max_fudged = -logarithmic_zero_epsilon;

            float t_with_flip = flipped ? (1.0f - t) : t; // t, but flipped if necessary to account for us flipping the range

            if ((v_min * v_max) < 0.0f) // Range crosses zero, so we have to do this in two parts
            {
                float zero_point_center = (-cast(float)ImMin(v_min, v_max)) / ImAbs(cast(float)v_max - cast(float)v_min); // The zero point in parametric space
                float zero_point_snap_L = zero_point_center - zero_deadzone_halfsize;
                float zero_point_snap_R = zero_point_center + zero_deadzone_halfsize;
                if (t_with_flip >= zero_point_snap_L && t_with_flip <= zero_point_snap_R)
                    result = cast(TYPE)0.0f; // Special case to make getting exactly zero possible (the epsilon prevents it otherwise)
                else if (t_with_flip < zero_point_center)
                    result = cast(TYPE)-(logarithmic_zero_epsilon * ImPow(-v_min_fudged / logarithmic_zero_epsilon, cast(FLOATTYPE)(1.0f - (t_with_flip / zero_point_snap_L))));
                else
                    result = cast(TYPE)(logarithmic_zero_epsilon * ImPow(v_max_fudged / logarithmic_zero_epsilon, cast(FLOATTYPE)((t_with_flip - zero_point_snap_R) / (1.0f - zero_point_snap_R))));
            }
            else if ((v_min < 0.0f) || (v_max < 0.0f)) // Entirely negative slider
                result = cast(TYPE)-(-v_max_fudged * ImPow(-v_min_fudged / -v_max_fudged, cast(FLOATTYPE)(1.0f - t_with_flip)));
            else
                result = cast(TYPE)(v_min_fudged * ImPow(v_max_fudged / v_min_fudged, cast(FLOATTYPE)t_with_flip));
        }
    }
    else
    {
        // Linear slider
        if (is_floating_point)
        {
            result = ImLerp(v_min, v_max, t);
        }
        else
        {
            // - For integer values we want the clicking position to match the grab box so we round above
            //   This code is carefully tuned to work with large values (e.g. high ranges of U64) while preserving this property..
            // - Not doing a *1.0 multiply at the end of a range as it tends to be lossy. While absolute aiming at a large s64/u64
            //   range is going to be imprecise anyway, with this check we at least make the edge values matches expected limits.
            if (t < 1.0)
            {
                FLOATTYPE v_new_off_f = cast(SIGNEDTYPE)(v_max - v_min) * t;
                result = cast(TYPE)(cast(SIGNEDTYPE)v_min + cast(SIGNEDTYPE)(v_new_off_f + cast(FLOATTYPE)(v_min > v_max ? -0.5 : 0.5)));
            }
            else
            {
                result = v_max;
            }
        }
    }

    return result;
}

// FIXME: Move more of the code into SliderBehavior()
bool SliderBehaviorT(TYPE, SIGNEDTYPE, FLOATTYPE)(const /*ref*/ ImRect bb, ImGuiID id, ImGuiDataType data_type, TYPE* v, TYPE v_min, TYPE v_max, string format, ImGuiSliderFlags flags, ImRect* out_grab_bb)
{
    ImGuiContext* g = GImGui;
    const ImGuiStyle* style = &g.Style;

    const ImGuiAxis axis = (flags & ImGuiSliderFlags.Vertical) ? ImGuiAxis.Y : ImGuiAxis.X;
    const bool is_logarithmic = (flags & ImGuiSliderFlags.Logarithmic) != 0;
    const bool is_floating_point = (data_type == ImGuiDataType.Float) || (data_type == ImGuiDataType.Double);

    const float grab_padding = 2.0f;
    const float slider_sz = (bb.Max[axis] - bb.Min[axis]) - grab_padding * 2.0f;
    float grab_sz = style.GrabMinSize;
    SIGNEDTYPE v_range = (v_min < v_max ? v_max - v_min : v_min - v_max);
    if (!is_floating_point && v_range >= 0)                                             // v_range < 0 may happen on integer overflows
        grab_sz = ImMax(cast(float)(slider_sz / (v_range + 1)), style.GrabMinSize);  // For integer sliders: if possible have the grab size represent 1 unit
    grab_sz = ImMin(grab_sz, slider_sz);
    const float slider_usable_sz = slider_sz - grab_sz;
    const float slider_usable_pos_min = bb.Min[axis] + grab_padding + grab_sz * 0.5f;
    const float slider_usable_pos_max = bb.Max[axis] - grab_padding - grab_sz * 0.5f;

    float logarithmic_zero_epsilon = 0.0f; // Only valid when is_logarithmic is true
    float zero_deadzone_halfsize = 0.0f; // Only valid when is_logarithmic is true
    if (is_logarithmic)
    {
        // When using logarithmic sliders, we need to clamp to avoid hitting zero, but our choice of clamp value greatly affects slider precision. We attempt to use the specified precision to estimate a good lower bound.
        const int decimal_precision = is_floating_point ? ImParseFormatPrecision(format, 3) : 1;
        logarithmic_zero_epsilon = ImPow(0.1f, cast(float)decimal_precision);
        zero_deadzone_halfsize = (style.LogSliderDeadzone * 0.5f) / ImMax(slider_usable_sz, 1.0f);
    }

    // Process interacting with the slider
    bool value_changed = false;
    if (g.ActiveId == id)
    {
        bool set_new_value = false;
        float clicked_t = 0.0f;
        if (g.ActiveIdSource == ImGuiInputSource.Mouse)
        {
            if (!g.IO.MouseDown[0])
            {
                ClearActiveID();
            }
            else
            {
                const float mouse_abs_pos = g.IO.MousePos[axis];
                clicked_t = (slider_usable_sz > 0.0f) ? ImClamp((mouse_abs_pos - slider_usable_pos_min) / slider_usable_sz, 0.0f, 1.0f) : 0.0f;
                if (axis == ImGuiAxis.Y)
                    clicked_t = 1.0f - clicked_t;
                set_new_value = true;
            }
        }
        else if (g.ActiveIdSource == ImGuiInputSource.Nav)
        {
            if (g.ActiveIdIsJustActivated)
            {
                g.SliderCurrentAccum = 0.0f; // Reset any stored nav delta upon activation
                g.SliderCurrentAccumDirty = false;
            }

            const ImVec2 input_delta2 = GetNavInputAmount2d(ImGuiNavDirSourceFlags.Keyboard | ImGuiNavDirSourceFlags.PadDPad, ImGuiInputReadMode.RepeatFast, 0.0f, 0.0f);
            float input_delta = (axis == ImGuiAxis.X) ? input_delta2.x : -input_delta2.y;
            if (input_delta != 0.0f)
            {
                const int decimal_precision = is_floating_point ? ImParseFormatPrecision(format, 3) : 0;
                if (decimal_precision > 0)
                {
                    input_delta /= 100.0f;    // Gamepad/keyboard tweak speeds in % of slider bounds
                    if (IsNavInputDown(ImGuiNavInput.TweakSlow))
                        input_delta /= 10.0f;
                }
                else
                {
                    if ((v_range >= -100.0f && v_range <= 100.0f) || IsNavInputDown(ImGuiNavInput.TweakSlow))
                        input_delta = ((input_delta < 0.0f) ? -1.0f : +1.0f) / cast(float)v_range; // Gamepad/keyboard tweak speeds in integer steps
                    else
                        input_delta /= 100.0f;
                }
                if (IsNavInputDown(ImGuiNavInput.TweakFast))
                    input_delta *= 10.0f;

                g.SliderCurrentAccum += input_delta;
                g.SliderCurrentAccumDirty = true;
            }

            float delta = g.SliderCurrentAccum;
            if (g.NavActivatePressedId == id && !g.ActiveIdIsJustActivated)
            {
                ClearActiveID();
            }
            else if (g.SliderCurrentAccumDirty)
            {
                clicked_t = ScaleRatioFromValueT!(TYPE, SIGNEDTYPE, FLOATTYPE)(data_type, *v, v_min, v_max, is_logarithmic, logarithmic_zero_epsilon, zero_deadzone_halfsize);

                if ((clicked_t >= 1.0f && delta > 0.0f) || (clicked_t <= 0.0f && delta < 0.0f)) // This is to avoid applying the saturation when already past the limits
                {
                    set_new_value = false;
                    g.SliderCurrentAccum = 0.0f; // If pushing up against the limits, don't continue to accumulate
                }
                else
                {
                    set_new_value = true;
                    float old_clicked_t = clicked_t;
                    clicked_t = ImSaturate(clicked_t + delta);

                    // Calculate what our "new" clicked_t will be, and thus how far we actually moved the slider, and subtract this from the accumulator
                    TYPE v_new = ScaleValueFromRatioT!(TYPE, SIGNEDTYPE, FLOATTYPE)(data_type, clicked_t, v_min, v_max, is_logarithmic, logarithmic_zero_epsilon, zero_deadzone_halfsize);
                    if (!(flags & ImGuiSliderFlags.NoRoundToFormat))
                        v_new = RoundScalarWithFormatT!(TYPE, SIGNEDTYPE)(format, data_type, v_new);
                    float new_clicked_t = ScaleRatioFromValueT!(TYPE, SIGNEDTYPE, FLOATTYPE)(data_type, v_new, v_min, v_max, is_logarithmic, logarithmic_zero_epsilon, zero_deadzone_halfsize);

                    if (delta > 0)
                        g.SliderCurrentAccum -= ImMin(new_clicked_t - old_clicked_t, delta);
                    else
                        g.SliderCurrentAccum -= ImMax(new_clicked_t - old_clicked_t, delta);
                }

                g.SliderCurrentAccumDirty = false;
            }
        }

        if (set_new_value)
        {
            TYPE v_new = ScaleValueFromRatioT!(TYPE, SIGNEDTYPE, FLOATTYPE)(data_type, clicked_t, v_min, v_max, is_logarithmic, logarithmic_zero_epsilon, zero_deadzone_halfsize);

            // Round to user desired precision based on format string
            if (!(flags & ImGuiSliderFlags.NoRoundToFormat))
                v_new = RoundScalarWithFormatT!(TYPE, SIGNEDTYPE)(format, data_type, v_new);

            // Apply result
            if (*v != v_new)
            {
                *v = v_new;
                value_changed = true;
            }
        }
    }

    if (slider_sz < 1.0f)
    {
        *out_grab_bb = ImRect(bb.Min, bb.Min);
    }
    else
    {
        // Output grab position so it can be displayed by the caller
        float grab_t = ScaleRatioFromValueT!(TYPE, SIGNEDTYPE, FLOATTYPE)(data_type, *v, v_min, v_max, is_logarithmic, logarithmic_zero_epsilon, zero_deadzone_halfsize);
        if (axis == ImGuiAxis.Y)
            grab_t = 1.0f - grab_t;
        const float grab_pos = ImLerp(slider_usable_pos_min, slider_usable_pos_max, grab_t);
        if (axis == ImGuiAxis.X)
            *out_grab_bb = ImRect(grab_pos - grab_sz * 0.5f, bb.Min.y + grab_padding, grab_pos + grab_sz * 0.5f, bb.Max.y - grab_padding);
        else
            *out_grab_bb = ImRect(bb.Min.x + grab_padding, grab_pos - grab_sz * 0.5f, bb.Max.x - grab_padding, grab_pos + grab_sz * 0.5f);
    }

    return value_changed;
}

// For 32-bit and larger types, slider bounds are limited to half the natural type range.
// So e.g. an integer Slider between INT_MAX-10 and INT_MAX will fail, but an integer Slider between INT_MAX/2-10 and INT_MAX/2 will be ok.
// It would be possible to lift that limitation with some work but it doesn't seem to be worth it for sliders.
bool SliderBehavior(const ImRect/*&*/ bb, ImGuiID id, ImGuiDataType data_type, void* p_v, const void* p_min, const void* p_max, string format, ImGuiSliderFlags flags, ImRect* out_grab_bb)
{
    // Read imgui.cpp "API BREAKING CHANGES" section for 1.78 if you hit this assert.
    IM_ASSERT((flags == 1 || (flags & ImGuiSliderFlags.InvalidMask_) == 0), "Invalid ImGuiSliderFlags flag!  Has the 'float power' argument been mistakenly cast to flags? Call function with ImGuiSliderFlags_Logarithmic flags instead.");

    ImGuiContext* g = GImGui;
    if ((g.LastItemData.InFlags & ImGuiItemFlags.ReadOnly) || (flags & ImGuiSliderFlags.ReadOnly))
        return false;

    switch (data_type)
    {
    case ImGuiDataType.S8:  { ImS32 v32 = cast(ImS32)*cast(ImS8*)p_v;  bool r = SliderBehaviorT!(ImS32, ImS32, float)(bb, id, ImGuiDataType.S32, &v32, *cast(const ImS8*)p_min,  *cast(const ImS8*)p_max,  format, flags, out_grab_bb); if (r) *cast(ImS8*)p_v  = cast(ImS8)v32;  return r; }
    case ImGuiDataType.U8:  { ImU32 v32 = cast(ImU32)*cast(ImU8*)p_v;  bool r = SliderBehaviorT!(ImU32, ImS32, float)(bb, id, ImGuiDataType.U32, &v32, *cast(const ImU8*)p_min,  *cast(const ImU8*)p_max,  format, flags, out_grab_bb); if (r) *cast(ImU8*)p_v  = cast(ImU8)v32;  return r; }
    case ImGuiDataType.S16: { ImS32 v32 = cast(ImS32)*cast(ImS16*)p_v; bool r = SliderBehaviorT!(ImS32, ImS32, float)(bb, id, ImGuiDataType.S32, &v32, *cast(const ImS16*)p_min, *cast(const ImS16*)p_max, format, flags, out_grab_bb); if (r) *cast(ImS16*)p_v = cast(ImS16)v32; return r; }
    case ImGuiDataType.U16: { ImU32 v32 = cast(ImU32)*cast(ImU16*)p_v; bool r = SliderBehaviorT!(ImU32, ImS32, float)(bb, id, ImGuiDataType.U32, &v32, *cast(const ImU16*)p_min, *cast(const ImU16*)p_max, format, flags, out_grab_bb); if (r) *cast(ImU16*)p_v = cast(ImU16)v32; return r; }
    case ImGuiDataType.S32:
        IM_ASSERT(*cast(const ImS32*)p_min >= IM_S32_MIN / 2 && *cast(const ImS32*)p_max <= IM_S32_MAX / 2);
        return SliderBehaviorT!(ImS32, ImS32, float )(bb, id, data_type, cast(ImS32*)p_v,  *cast(const ImS32*)p_min,  *cast(const ImS32*)p_max,  format, flags, out_grab_bb);
    case ImGuiDataType.U32:
        IM_ASSERT(*cast(const ImU32*)p_max <= IM_U32_MAX / 2);
        return SliderBehaviorT!(ImU32, ImS32, float )(bb, id, data_type, cast(ImU32*)p_v,  *cast(const ImU32*)p_min,  *cast(const ImU32*)p_max,  format, flags, out_grab_bb);
    case ImGuiDataType.S64:
        IM_ASSERT(*cast(const ImS64*)p_min >= IM_S64_MIN / 2 && *cast(const ImS64*)p_max <= IM_S64_MAX / 2);
        return SliderBehaviorT!(ImS64, ImS64, double)(bb, id, data_type, cast(ImS64*)p_v,  *cast(const ImS64*)p_min,  *cast(const ImS64*)p_max,  format, flags, out_grab_bb);
    case ImGuiDataType.U64:
        IM_ASSERT(*cast(const ImU64*)p_max <= IM_U64_MAX / 2);
        return SliderBehaviorT!(ImU64, ImS64, double)(bb, id, data_type, cast(ImU64*)p_v,  *cast(const ImU64*)p_min,  *cast(const ImU64*)p_max,  format, flags, out_grab_bb);
    case ImGuiDataType.Float:
        IM_ASSERT(*cast(const float*)p_min >= -FLT_MAX / 2.0f && *cast(const float*)p_max <= FLT_MAX / 2.0f);
        return SliderBehaviorT!(float, float, float )(bb, id, data_type, cast(float*)p_v,  *cast(const float*)p_min,  *cast(const float*)p_max,  format, flags, out_grab_bb);
    case ImGuiDataType.Double:
        IM_ASSERT(*cast(const double*)p_min >= -DBL_MAX / 2.0f && *cast(const double*)p_max <= DBL_MAX / 2.0f);
        return SliderBehaviorT!(double,double,double)(bb, id, data_type, cast(double*)p_v, *cast(const double*)p_min, *cast(const double*)p_max, format, flags, out_grab_bb);
    case ImGuiDataType.COUNT: break;
    default: break;
    }
    IM_ASSERT(0);
    return false;
}

// Note: p_data, p_min and p_max are _pointers_ to a memory address holding the data. For a slider, they are all required.
// Read code of e.g. SliderFloat(), SliderInt() etc. or examples in 'Demo->Widgets->Data Types' to understand how to use this function directly.
bool SliderScalar(string label, ImGuiDataType data_type, void* p_data, const void* p_min, const void* p_max, string format = NULL, ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    ImGuiContext* g = GImGui;
    const ImGuiStyle* style = &g.Style;
    const ImGuiID id = window.GetID(label);
    const float w = CalcItemWidth();

    const ImVec2 label_size = CalcTextSize(label, true);
    const ImRect frame_bb = ImRect(window.DC.CursorPos, window.DC.CursorPos + ImVec2(w, label_size.y + style.FramePadding.y * 2.0f));
    const ImRect total_bb = ImRect(frame_bb.Min, frame_bb.Max + ImVec2(label_size.x > 0.0f ? style.ItemInnerSpacing.x + label_size.x : 0.0f, 0.0f));

    const bool temp_input_allowed = (flags & ImGuiSliderFlags.NoInput) == 0;
    ItemSize(total_bb, style.FramePadding.y);
    if (!ItemAdd(total_bb, id, &frame_bb, temp_input_allowed ? ImGuiItemAddFlags.Focusable : ImGuiItemAddFlags.None))
        return false;

    // Default format string when passing NULL
    if (format == NULL)
        format = DataTypeGetInfo(data_type).PrintFmt;
    else if (data_type == ImGuiDataType.S32 && format != "%d") // (FIXME-LEGACY: Patch old "%.0f" format string to use "%d", read function more details.)
        format = PatchFormatStringFloatToInt(format);

    // Tabbing or CTRL-clicking on Slider turns it into an input box
    const bool hovered = ItemHoverable(frame_bb, id);
    bool temp_input_is_active = temp_input_allowed && TempInputIsActive(id);
    if (!temp_input_is_active)
    {
        const bool focus_requested = temp_input_allowed && (g.LastItemData.StatusFlags & ImGuiItemStatusFlags.Focused) != 0;
        const bool clicked = (hovered && g.IO.MouseClicked[0]);
        if (focus_requested || clicked || g.NavActivateId == id || g.NavInputId == id)
        {
            SetActiveID(id, window);
            SetFocusID(id, window);
            FocusWindow(window);
            g.ActiveIdUsingNavDirMask |= (1 << ImGuiDir.Left) | (1 << ImGuiDir.Right);
            if (temp_input_allowed && (focus_requested || (clicked && g.IO.KeyCtrl) || g.NavInputId == id))
                temp_input_is_active = true;
        }
    }

    if (temp_input_is_active)
    {
        // Only clamp CTRL+Click input when ImGuiSliderFlags_AlwaysClamp is set
        const bool is_clamp_input = (flags & ImGuiSliderFlags.AlwaysClamp) != 0;
        return TempInputScalar(frame_bb, id, label, data_type, p_data, format, is_clamp_input ? p_min : NULL, is_clamp_input ? p_max : NULL);
    }

    // Draw frame
    const ImU32 frame_col = GetColorU32(g.ActiveId == id ? ImGuiCol.FrameBgActive : hovered ? ImGuiCol.FrameBgHovered : ImGuiCol.FrameBg);
    RenderNavHighlight(frame_bb, id);
    RenderFrame(frame_bb.Min, frame_bb.Max, frame_col, true, g.Style.FrameRounding);

    // Slider behavior
    ImRect grab_bb;
    const bool value_changed = SliderBehavior(frame_bb, id, data_type, p_data, p_min, p_max, format, flags, &grab_bb);
    if (value_changed)
        MarkItemEdited(id);

    // Render grab
    if (grab_bb.Max.x > grab_bb.Min.x)
        window.DrawList.AddRectFilled(grab_bb.Min, grab_bb.Max, GetColorU32(g.ActiveId == id ? ImGuiCol.SliderGrabActive : ImGuiCol.SliderGrab), style.GrabRounding);

    // Display value using user-provided display format so user can add prefix/suffix/decorations to the value.
    char[64] value_buf;
    int value_buf_end = DataTypeFormatString(value_buf, data_type, p_data, format);
    if (g.LogEnabled)
        LogSetNextTextDecoration("{", "}");
    RenderTextClipped(frame_bb.Min, frame_bb.Max, cast(string)value_buf[0..value_buf_end], NULL, ImVec2(0.5f, 0.5f));

    if (label_size.x > 0.0f)
        RenderText(ImVec2(frame_bb.Max.x + style.ItemInnerSpacing.x, frame_bb.Min.y + style.FramePadding.y), label);

    IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags);
    return value_changed;
}

// Add multiple sliders on 1 line for compact edition of multiple components
bool SliderScalarN(string label, ImGuiDataType data_type, void* v, int components, const void* v_min, const void* v_max, string format = NULL, ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    ImGuiContext* g = GImGui;
    bool value_changed = false;
    BeginGroup();
    PushID(label);
    PushMultiItemsWidths(components, CalcItemWidth());
    size_t type_size = GDataTypeInfo[data_type].Size;
    for (int i = 0; i < components; i++)
    {
        PushID(i);
        if (i > 0)
            SameLine(0, g.Style.ItemInnerSpacing.x);
        value_changed |= SliderScalar("", data_type, v, v_min, v_max, format, flags);
        PopID();
        PopItemWidth();
        v = cast(void*)(cast(char*)v + type_size);
    }
    PopID();

    string label_end = FindRenderedTextEnd(label);
    if (label_end.length != 0)
    {
        SameLine(0, g.Style.ItemInnerSpacing.x);
        TextEx(label_end);
    }

    EndGroup();
    return value_changed;
}

bool SliderFloat(string label, float* v, float v_min, float v_max, string format = "%.3f", ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    return SliderScalar(label, ImGuiDataType.Float, v, &v_min, &v_max, format, flags);
}

bool SliderFloat2(string label, float[/*2*/] v, float v_min, float v_max, string format = "%.3f", ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    return SliderScalarN(label, ImGuiDataType.Float, v.ptr, 2, &v_min, &v_max, format, flags);
}

bool SliderFloat3(string label, float[/*3*/] v, float v_min, float v_max, string format = "%.3f", ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    return SliderScalarN(label, ImGuiDataType.Float, v.ptr, 3, &v_min, &v_max, format, flags);
}

bool SliderFloat4(string label, float[/*4*/] v, float v_min, float v_max, string format = "%.3f", ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    return SliderScalarN(label, ImGuiDataType.Float, v.ptr, 4, &v_min, &v_max, format, flags);
}

bool SliderFloat2(string label, ImVec2* v, float v_min, float v_max, string format = "%.3f", ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    return SliderFloat2(label, (&v.x)[0..2], v_min, v_max, format, flags);
}

bool SliderAngle(string label, float* v_rad, float v_degrees_min = -360.0f, float v_degrees_max = +360.0f, string format = "%.0f deg", ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    if (format == NULL)
        format = "%.0f deg";
    float v_deg = (*v_rad) * 360.0f / (2 * IM_PI);
    bool value_changed = SliderFloat(label, &v_deg, v_degrees_min, v_degrees_max, format, flags);
    *v_rad = v_deg * (2 * IM_PI) / 360.0f;
    return value_changed;
}

bool SliderInt(string label, int* v, int v_min, int v_max, string format = "%d", ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    return SliderScalar(label, ImGuiDataType.S32, v, &v_min, &v_max, format, flags);
}

bool SliderInt2(string label, int[/*2*/] v, int v_min, int v_max, string format = "%d", ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    return SliderScalarN(label, ImGuiDataType.S32, v.ptr, 2, &v_min, &v_max, format, flags);
}

bool SliderInt3(string label, int[/*3*/] v, int v_min, int v_max, string format = "%d", ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    return SliderScalarN(label, ImGuiDataType.S32, v.ptr, 3, &v_min, &v_max, format, flags);
}

bool SliderInt4(string label, int[/*4*/] v, int v_min, int v_max, string format = "%d", ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    return SliderScalarN(label, ImGuiDataType.S32, v.ptr, 4, &v_min, &v_max, format, flags);
}

bool VSliderScalar(string label, const ImVec2/*&*/ size, ImGuiDataType data_type, void* p_data, const void* p_min, const void* p_max, string format = NULL, float power = 1.0f, ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    ImGuiContext* g = GImGui;
    const ImGuiStyle* style = &g.Style;
    const ImGuiID id = window.GetID(label);

    const ImVec2 label_size = CalcTextSize(label, true);
    const ImRect frame_bb = ImRect(window.DC.CursorPos, window.DC.CursorPos + size);
    const ImRect bb = ImRect(frame_bb.Min, frame_bb.Max + ImVec2(label_size.x > 0.0f ? style.ItemInnerSpacing.x + label_size.x : 0.0f, 0.0f));

    ItemSize(bb, style.FramePadding.y);
    if (!ItemAdd(frame_bb, id))
        return false;

    // Default format string when passing NULL
    if (format == NULL)
        format = DataTypeGetInfo(data_type).PrintFmt;
    else if (data_type == ImGuiDataType.S32 && format != "%d") // (FIXME-LEGACY: Patch old "%.0f" format string to use "%d", read function more details.)
        format = PatchFormatStringFloatToInt(format);

    const bool hovered = ItemHoverable(frame_bb, id);
    if ((hovered && g.IO.MouseClicked[0]) || g.NavActivateId == id || g.NavInputId == id)
    {
        SetActiveID(id, window);
        SetFocusID(id, window);
        FocusWindow(window);
        g.ActiveIdUsingNavDirMask |= (1 << ImGuiDir.Up) | (1 << ImGuiDir.Down);
    }

    // Draw frame
    const ImU32 frame_col = GetColorU32(g.ActiveId == id ? ImGuiCol.FrameBgActive : hovered ? ImGuiCol.FrameBgHovered : ImGuiCol.FrameBg);
    RenderNavHighlight(frame_bb, id);
    RenderFrame(frame_bb.Min, frame_bb.Max, frame_col, true, g.Style.FrameRounding);

    // Slider behavior
    ImRect grab_bb;
    const bool value_changed = SliderBehavior(frame_bb, id, data_type, p_data, p_min, p_max, format, flags | ImGuiSliderFlags.Vertical, &grab_bb);
    if (value_changed)
        MarkItemEdited(id);

    // Render grab
    if (grab_bb.Max.y > grab_bb.Min.y)
        window.DrawList.AddRectFilled(grab_bb.Min, grab_bb.Max, GetColorU32(g.ActiveId == id ? ImGuiCol.SliderGrabActive : ImGuiCol.SliderGrab), style.GrabRounding);

    // Display value using user-provided display format so user can add prefix/suffix/decorations to the value.
    // For the vertical slider we allow centered text to overlap the frame padding
    char[64] value_buf;
    int value_buf_end = DataTypeFormatString(value_buf, data_type, p_data, format);
    RenderTextClipped(ImVec2(frame_bb.Min.x, frame_bb.Min.y + style.FramePadding.y), frame_bb.Max, cast(string)value_buf[0..value_buf_end], NULL, ImVec2(0.5f, 0.0f));
    if (label_size.x > 0.0f)
        RenderText(ImVec2(frame_bb.Max.x + style.ItemInnerSpacing.x, frame_bb.Min.y + style.FramePadding.y), label);

    return value_changed;
}

bool VSliderFloat(string label, const ImVec2/*&*/ size, float* v, float v_min, float v_max, string format = "%.3f", ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    return VSliderScalar(label, size, ImGuiDataType.Float, v, &v_min, &v_max, format, flags);
}

bool VSliderInt(string label, const ImVec2/*&*/ size, int* v, int v_min, int v_max, string format = "%d", ImGuiSliderFlags flags = ImGuiSliderFlags.None)
{
    return VSliderScalar(label, size, ImGuiDataType.S32, v, &v_min, &v_max, format, flags);
}

static if (!IMGUI_DISABLE_OBSOLETE_FUNCTIONS) {

// Obsolete versions with power parameter. See https://github.com/ocornut/imgui/issues/3361 for details.
bool SliderScalar(string label, ImGuiDataType data_type, void* p_data, const void* p_min, const void* p_max, string format, float power)
{
    ImGuiSliderFlags slider_flags = ImGuiSliderFlags.None;
    if (power != 1.0f)
    {
        IM_ASSERT(power == 1.0f, "Call function with ImGuiSliderFlags_Logarithmic flags instead of using the old 'float power' function!");
        slider_flags |= ImGuiSliderFlags.Logarithmic;   // Fallback for non-asserting paths
    }
    return SliderScalar(label, data_type, p_data, p_min, p_max, format, slider_flags);
}

bool SliderScalarN(string label, ImGuiDataType data_type, void* v, int components, const void* v_min, const void* v_max, string format, float power)
{
    ImGuiSliderFlags slider_flags = ImGuiSliderFlags.None;
    if (power != 1.0f)
    {
        IM_ASSERT(power == 1.0f, "Call function with ImGuiSliderFlags_Logarithmic flags instead of using the old 'float power' function!");
        slider_flags |= ImGuiSliderFlags.Logarithmic;   // Fallback for non-asserting paths
    }
    return SliderScalarN(label, data_type, v, components, v_min, v_max, format, slider_flags);
}

} // IMGUI_DISABLE_OBSOLETE_FUNCTIONS

//-------------------------------------------------------------------------
// [SECTION] Widgets: InputScalar, InputFloat, InputInt, etc.
//-------------------------------------------------------------------------
// - ImParseFormatFindStart() [Internal]
// - ImParseFormatFindEnd() [Internal]
// - ImParseFormatTrimDecorations() [Internal]
// - ImParseFormatPrecision() [Internal]
// - TempInputTextScalar() [Internal]
// - InputScalar()
// - InputScalarN()
// - InputFloat()
// - InputFloat2()
// - InputFloat3()
// - InputFloat4()
// - InputInt()
// - InputInt2()
// - InputInt3()
// - InputInt4()
// - InputDouble()
//-------------------------------------------------------------------------

// We don't use strchr() because our strings are usually very short and often start with '%'
size_t ImParseFormatFindStart(string fmt)
{
    size_t index = 0;
    while (index < fmt.length)
    {
        char c = fmt[index];
        if (c == '%' && index + 1 < fmt.length && fmt[index + 1] != '%')
            return index;
        else if (c == '%')
            index++;
        index++;
    }
    return index;
}

size_t ImParseFormatFindEnd(string fmt, size_t start)
{
    // Printf/scanf types modifiers: I/L/h/j/l/t/w/z. Other uppercase letters qualify as types aka end of the format.
    if (start == fmt.length || fmt[start] != '%')
        return start;
    const uint ignored_uppercase_mask = (1 << ('I'-'A')) | (1 << ('L'-'A'));
    const uint ignored_lowercase_mask = (1 << ('h'-'a')) | (1 << ('j'-'a')) | (1 << ('l'-'a')) | (1 << ('t'-'a')) | (1 << ('w'-'a')) | (1 << ('z'-'a'));
    size_t index = start;
    for (; index < fmt.length; index++)
    {
        char c = fmt[index];
        if (c >= 'A' && c <= 'Z' && ((1 << (c - 'A')) & ignored_uppercase_mask) == 0)
            return index + 1;
        if (c >= 'a' && c <= 'z' && ((1 << (c - 'a')) & ignored_lowercase_mask) == 0)
            return index + 1;
    }
    return index;
}

// Extract the format out of a format string with leading or trailing decorations
//  fmt = "blah blah"  -> return fmt
//  fmt = "%.3f"       -> return fmt
//  fmt = "hello %.3f" -> return fmt + 6
//  fmt = "%.3f hello" -> return buf written with "%.3f"
string ImParseFormatTrimDecorations(string fmt)
{
    size_t fmt_start = ImParseFormatFindStart(fmt);
    if (fmt_start == fmt.length || fmt[fmt_start] != '%')
        return fmt;
    size_t fmt_end = ImParseFormatFindEnd(fmt, fmt_start);
    // D_IMGUI: Since we don't need a zero terminator, no copy is necessary
    return fmt[fmt_start..fmt_end];
}

// Parse display precision back from the display format string
// FIXME: This is still used by some navigation code path to infer a minimum tweak step, but we should aim to rework widgets so it isn't needed.
int ImParseFormatPrecision(string fmt, int default_precision)
{
    size_t fmt_start = ImParseFormatFindStart(fmt);
    if (fmt_start == fmt.length || fmt[fmt_start] != '%')
        return default_precision;
    fmt_start++;
    while (fmt_start < fmt.length && fmt[fmt_start] >= '0' && fmt[fmt_start] <= '9')
        fmt_start++;
    int precision = INT_MAX;
    if (fmt_start < fmt.length && fmt[fmt_start] == '.')
    {
        fmt_start += ImAtoi!int(fmt[fmt_start + 1..$], &precision).length;
        if (precision < 0 || precision > 99)
            precision = default_precision;
    }
    if (fmt_start < fmt.length && (fmt[fmt_start] == 'e' || fmt[fmt_start] == 'E')) // Maximum precision with scientific notation
        precision = -1;
    if (fmt_start < fmt.length && (fmt[fmt_start] == 'g' || fmt[fmt_start] == 'G') && precision == INT_MAX)
        precision = -1;
    return (precision == INT_MAX) ? default_precision : precision;
}

// Create text input in place of another active widget (e.g. used when doing a CTRL+Click on drag/slider widgets)
// FIXME: Facilitate using this in variety of other situations.
bool TempInputText(const ImRect/*&*/ bb, ImGuiID id, string label, char[] buf, ImGuiInputTextFlags flags)
{
    // On the first frame, g.TempInputTextId == 0, then on subsequent frames it becomes == id.
    // We clear ActiveID on the first frame to allow the InputText() taking it back.
    ImGuiContext* g = GImGui;
    const bool init = (g.TempInputId != id);
    if (init)
        ClearActiveID();

    g.CurrentWindow.DC.CursorPos = bb.Min;
    bool value_changed = InputTextEx(label, NULL, buf, bb.GetSize(), flags | ImGuiInputTextFlags.MergedItem);
    if (init)
    {
        // First frame we started displaying the InputText widget, we expect it to take the active id.
        IM_ASSERT(g.ActiveId == id);
        g.TempInputId = g.ActiveId;
    }
    return value_changed;
}

// Note that Drag/Slider functions are only forwarding the min/max values clamping values if the ImGuiSliderFlags_AlwaysClamp flag is set!
// This is intended: this way we allow CTRL+Click manual input to set a value out of bounds, for maximum flexibility.
// However this may not be ideal for all uses, as some user code may break on out of bound values.
bool TempInputScalar(const ImRect/*&*/ bb, ImGuiID id, string label, ImGuiDataType data_type, void* p_data, string format, const (void)* p_clamp_min = NULL, const (void)* p_clamp_max = NULL)
{
    ImGuiContext* g = GImGui;

    char[32] data_buf;
    format = ImParseFormatTrimDecorations(format);
    int length = DataTypeFormatString(data_buf, data_type, p_data, format);
    if (data_buf.length > length)
        data_buf[length] = 0;

    ImGuiInputTextFlags flags = ImGuiInputTextFlags.AutoSelectAll | ImGuiInputTextFlags.NoMarkEdited;
    flags |= ((data_type == ImGuiDataType.Float || data_type == ImGuiDataType.Double) ? ImGuiInputTextFlags.CharsScientific : ImGuiInputTextFlags.CharsDecimal);
    bool value_changed = false;
    if (TempInputText(bb, id, label, data_buf, flags))
    {
        // Backup old value
        size_t data_type_size = DataTypeGetInfo(data_type).Size;
        ImGuiDataTypeTempStorage data_backup;
        memcpy(&data_backup, p_data, data_type_size);

        // Apply new value (or operations) then clamp
        DataTypeApplyOpFromText(ImCstring(data_buf), cast(string)g.InputTextState.InitialTextA.asArray(), data_type, p_data, NULL);
        if (p_clamp_min || p_clamp_max)
        {
            if (p_clamp_min && p_clamp_max && DataTypeCompare(data_type, p_clamp_min, p_clamp_max) > 0)
                ImSwap(p_clamp_min, p_clamp_max);
            DataTypeClamp(data_type, p_data, p_clamp_min, p_clamp_max);
        }

        // Only mark as edited if new value is different
        value_changed = memcmp(&data_backup, p_data, data_type_size) != 0;
        if (value_changed)
            MarkItemEdited(id);
    }
    return value_changed;
}

// Note: p_data, p_step, p_step_fast are _pointers_ to a memory address holding the data. For an Input widget, p_step and p_step_fast are optional.
// Read code of e.g. InputFloat(), InputInt() etc. or examples in 'Demo->Widgets->Data Types' to understand how to use this function directly.
bool InputScalar(string label, ImGuiDataType data_type, void* p_data, const void* p_step = NULL, const void* p_step_fast = NULL, string format = NULL, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    ImGuiContext* g = GImGui;
    ImGuiStyle* style = &g.Style;

    if (format is NULL)
        format = DataTypeGetInfo(data_type).PrintFmt;

    char[64] buf;
    DataTypeFormatString(buf, data_type, p_data, format);

    bool value_changed = false;
    if ((flags & (ImGuiInputTextFlags.CharsHexadecimal | ImGuiInputTextFlags.CharsScientific)) == 0)
        flags |= ImGuiInputTextFlags.CharsDecimal;
    flags |= ImGuiInputTextFlags.AutoSelectAll;
    flags |= ImGuiInputTextFlags.NoMarkEdited;  // We call MarkItemEdited() ourselves by comparing the actual data rather than the string.

    if (p_step != NULL)
    {
        const float button_size = GetFrameHeight();

        BeginGroup(); // The only purpose of the group here is to allow the caller to query item data e.g. IsItemActive()
        PushID(label);
        SetNextItemWidth(ImMax(1.0f, CalcItemWidth() - (button_size + style.ItemInnerSpacing.x) * 2));
        if (InputText("", buf, flags)) // PushId(label) + "" gives us the expected ID from outside point of view
            value_changed = DataTypeApplyOpFromText(ImCstring(buf.ptr), cast(string)g.InputTextState.InitialTextA.asArray()[0..$-1], data_type, p_data, format);

        // Step buttons
        const ImVec2 backup_frame_padding = style.FramePadding;
        style.FramePadding.x = style.FramePadding.y;
        ImGuiButtonFlags button_flags = ImGuiButtonFlags.Repeat | ImGuiButtonFlags.DontClosePopups;
        if (flags & ImGuiInputTextFlags.ReadOnly)
            BeginDisabled(true);
        SameLine(0, style.ItemInnerSpacing.x);
        if (ButtonEx("-", ImVec2(button_size, button_size), button_flags))
        {
            DataTypeApplyOp(data_type, '-', p_data, p_data, g.IO.KeyCtrl && p_step_fast ? p_step_fast : p_step);
            value_changed = true;
        }
        SameLine(0, style.ItemInnerSpacing.x);
        if (ButtonEx("+", ImVec2(button_size, button_size), button_flags))
        {
            DataTypeApplyOp(data_type, '+', p_data, p_data, g.IO.KeyCtrl && p_step_fast ? p_step_fast : p_step);
            value_changed = true;
        }
        if (flags & ImGuiInputTextFlags.ReadOnly)
            EndDisabled();

        string label_end = FindRenderedTextEnd(label);
        if (label_end.length != 0)
        {
            SameLine(0, style.ItemInnerSpacing.x);
            TextEx(label_end);
        }
        style.FramePadding = backup_frame_padding;

        PopID();
        EndGroup();
    }
    else
    {
        if (InputText(label, buf, flags))
            value_changed = DataTypeApplyOpFromText(ImCstring(buf.ptr), cast(string)g.InputTextState.InitialTextA.asArray()[0..$-1], data_type, p_data, format);
    }
    if (value_changed)
        MarkItemEdited(g.LastItemData.ID);

    return value_changed;
}

bool InputScalarN(string label, ImGuiDataType data_type, void* p_data, int components, const void* p_step = NULL, const void* p_step_fast = NULL, string format = NULL, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    ImGuiContext* g = GImGui;
    bool value_changed = false;
    BeginGroup();
    PushID(label);
    PushMultiItemsWidths(components, CalcItemWidth());
    size_t type_size = GDataTypeInfo[data_type].Size;
    for (int i = 0; i < components; i++)
    {
        PushID(i);
        if (i > 0)
            SameLine(0, g.Style.ItemInnerSpacing.x);
        value_changed |= InputScalar("##v", data_type, p_data, p_step, p_step_fast, format, flags);
        PopID();
        PopItemWidth();
        p_data = cast(void*)(cast(char*)p_data + type_size);
    }
    PopID();

    string label_end = FindRenderedTextEnd(label);
    if (label_end.length != 0)
    {
        SameLine(0.0f, g.Style.ItemInnerSpacing.x);
        TextEx(label_end);
    }

    EndGroup();
    return value_changed;
}

bool InputFloat(string label, float* v, float step = 0.0f, float step_fast = 0.0f, string format = "%.3f", ImGuiInputTextFlags flags = ImGuiInputTextFlags.None)
{
    flags |= ImGuiInputTextFlags.CharsScientific;
    return InputScalar(label, ImGuiDataType.Float, cast(void*)v, cast(void*)(step > 0.0f ? &step : NULL), cast(void*)(step_fast > 0.0f ? &step_fast : NULL), format, flags);
}

bool InputFloat2(string label, float[/*2*/] v, string format = "%.3f", ImGuiInputTextFlags flags = ImGuiInputTextFlags.None)
{
    return InputScalarN(label, ImGuiDataType.Float, v.ptr, 2, NULL, NULL, format, flags);
}

bool InputFloat3(string label, float[/*3*/] v, string format = "%.3f", ImGuiInputTextFlags flags = ImGuiInputTextFlags.None)
{
    return InputScalarN(label, ImGuiDataType.Float, v.ptr, 3, NULL, NULL, format, flags);
}

bool InputFloat4(string label, float[/*4*/] v, string format = "%.3f", ImGuiInputTextFlags flags = ImGuiInputTextFlags.None)
{
    return InputScalarN(label, ImGuiDataType.Float, v.ptr, 4, NULL, NULL, format, flags);
}

bool InputInt(string label, int* v, int step = 1, int step_fast = 100, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None)
{
    // Hexadecimal input provided as a convenience but the flag name is awkward. Typically you'd use InputText() to parse your own data, if you want to handle prefixes.
    string format = (flags & ImGuiInputTextFlags.CharsHexadecimal) ? "%08X" : "%d";
    return InputScalar(label, ImGuiDataType.S32, cast(void*)v, cast(void*)(step > 0 ? &step : NULL), cast(void*)(step_fast > 0 ? &step_fast : NULL), format, flags);
}

bool InputInt2(string label, int[/*2*/] v, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None)
{
    return InputScalarN(label, ImGuiDataType.S32, v.ptr, 2, NULL, NULL, "%d", flags);
}

bool InputInt3(string label, int[/*3*/] v, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None)
{
    return InputScalarN(label, ImGuiDataType.S32, v.ptr, 3, NULL, NULL, "%d", flags);
}

bool InputInt4(string label, int[/*4*/] v, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None)
{
    return InputScalarN(label, ImGuiDataType.S32, v.ptr, 4, NULL, NULL, "%d", flags);
}

bool InputDouble(string label, double* v, double step = 0.0, double step_fast = 0.0, string format = "%.6f", ImGuiInputTextFlags flags = ImGuiInputTextFlags.None)
{
    flags |= ImGuiInputTextFlags.CharsScientific;
    return InputScalar(label, ImGuiDataType.Double, cast(void*)v, cast(void*)(step > 0.0 ? &step : NULL), cast(void*)(step_fast > 0.0 ? &step_fast : NULL), format, flags);
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: InputText, InputTextMultiline, InputTextWithHint
//-------------------------------------------------------------------------
// - InputText()
// - InputTextWithHint()
// - InputTextMultiline()
// - InputTextEx() [Internal]
//-------------------------------------------------------------------------

bool InputText(string label, char[] buf, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None, ImGuiInputTextCallback callback = NULL, void* user_data = NULL)
{
    IM_ASSERT(!(flags & ImGuiInputTextFlags.Multiline)); // call InputTextMultiline()
    return InputTextEx(label, NULL, buf, ImVec2(0, 0), flags, callback, user_data);
}

bool InputTextMultiline(string label, char[] buf, const ImVec2/*&*/ size = ImVec2(0, 0), ImGuiInputTextFlags flags = ImGuiInputTextFlags.None, ImGuiInputTextCallback callback = NULL, void* user_data = NULL)
{
    return InputTextEx(label, NULL, buf, size, flags | ImGuiInputTextFlags.Multiline, callback, user_data);
}

bool InputTextWithHint(string label, string hint, char[] buf, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None, ImGuiInputTextCallback callback = NULL, void* user_data = NULL)
{
    IM_ASSERT(!(flags & ImGuiInputTextFlags.Multiline)); // call InputTextMultiline()
    return InputTextEx(label, hint, buf, ImVec2(0, 0), flags, callback, user_data);
}

int InputTextCalcTextLenAndLineCount(const char[] text_begin, size_t* out_text_end)
{
    int line_count = 0;
    const (char)*s = text_begin.ptr;
    char c = *s++;
    while (c) { // We are only matching for \n so we can ignore UTF-8 decoding
        if (c == '\n')
            line_count++;
        c = *s++;
    }
    s--;
    if (s[0] != '\n' && s[0] != '\r')
        line_count++;
    *out_text_end = s - text_begin.ptr;
    return line_count;
}

ImVec2 InputTextCalcTextSizeW(const ImWchar* text_begin, const ImWchar* text_end, const (ImWchar)** remaining = NULL, ImVec2* out_offset = NULL, bool stop_on_new_line = false)
{
    ImGuiContext* g = GImGui;
    ImFont* font = g.Font;
    const float line_height = g.FontSize;
    const float scale = line_height / font.FontSize;

    ImVec2 text_size = ImVec2(0, 0);
    float line_width = 0.0f;

    const (ImWchar)* s = text_begin;
    while (s < text_end)
    {
        uint c = cast(uint)(*s++);
        if (c == '\n')
        {
            text_size.x = ImMax(text_size.x, line_width);
            text_size.y += line_height;
            line_width = 0.0f;
            if (stop_on_new_line)
                break;
            continue;
        }
        if (c == '\r')
            continue;

        const float char_width = font.GetCharAdvance(cast(ImWchar)c) * scale;
        line_width += char_width;
    }

    if (text_size.x < line_width)
        text_size.x = line_width;

    if (out_offset)
        *out_offset = ImVec2(line_width, text_size.y + line_height);  // offset allow for the possibility of sitting after a trailing \n

    if (line_width > 0 || text_size.y == 0.0f)                        // whereas size.y will ignore the trailing \n
        text_size.y += line_height;

    if (remaining)
        *remaining = s;

    return text_size;
}

// Wrapper for stb_textedit.h to edit text (our wrapper is for: statically sized buffer, single-line, wchar characters. InputText converts between UTF-8 and wchar)
// namespace ImStb
// {

int     STB_TEXTEDIT_STRINGLEN(const ImGuiInputTextState* obj)                             { return obj.CurLenW; }
ImWchar STB_TEXTEDIT_GETCHAR(const ImGuiInputTextState* obj, int idx)                      { return obj.TextW[idx]; }
float   STB_TEXTEDIT_GETWIDTH(ImGuiInputTextState* obj, int line_start_idx, int char_idx)  { ImWchar c = obj.TextW[line_start_idx + char_idx]; if (c == '\n') return STB_TEXTEDIT_GETWIDTH_NEWLINE; ImGuiContext* g = GImGui; return g.Font.GetCharAdvance(c) * (g.FontSize / g.Font.FontSize); }
int     STB_TEXTEDIT_KEYTOTEXT(int key)                                                    { return key >= 0x200000 ? 0 : key; }
__gshared ImWchar STB_TEXTEDIT_NEWLINE = '\n';
void    STB_TEXTEDIT_LAYOUTROW(StbTexteditRow* r, ImGuiInputTextState* obj, int line_start_idx)
{
    const (ImWchar)* text = obj.TextW.Data;
    const (ImWchar)* text_remaining = NULL;
    const ImVec2 size = InputTextCalcTextSizeW(text + line_start_idx, text + obj.CurLenW, &text_remaining, NULL, true);
    r.x0 = 0.0f;
    r.x1 = size.x;
    r.baseline_y_delta = size.y;
    r.ymin = 0.0f;
    r.ymax = size.y;
    r.num_chars = cast(int)(text_remaining - (text + line_start_idx));
}

// When ImGuiInputTextFlags_Password is set, we don't want actions such as CTRL+Arrow to leak the fact that underlying data are blanks or separators.
bool is_separator(uint c)                                        { return ImCharIsBlankW(c) || c==',' || c==';' || c=='(' || c==')' || c=='{' || c=='}' || c=='[' || c==']' || c=='|'; }
int  is_word_boundary_from_right(ImGuiInputTextState* obj, int idx)      { if (obj.Flags & ImGuiInputTextFlags.Password) return 0; return idx > 0 ? (is_separator(obj.TextW[idx - 1]) && !is_separator(obj.TextW[idx]) ) : 1; }
int  STB_TEXTEDIT_MOVEWORDLEFT_IMPL(ImGuiInputTextState* obj, int idx)   { idx--; while (idx >= 0 && !is_word_boundary_from_right(obj, idx)) idx--; return idx < 0 ? 0 : idx; }
static if (D_IMGUI_Apple) {    // FIXME: Move setting to IO structure
    int  is_word_boundary_from_left(ImGuiInputTextState* obj, int idx)       { if (obj.Flags & ImGuiInputTextFlags.Password) return 0; return idx > 0 ? (!is_separator(obj.TextW[idx - 1]) && is_separator(obj.TextW[idx]) ) : 1; }
    int  STB_TEXTEDIT_MOVEWORDRIGHT_IMPL(ImGuiInputTextState* obj, int idx)  { idx++; int len = obj.CurLenW; while (idx < len && !is_word_boundary_from_left(obj, idx)) idx++; return idx > len ? len : idx; }
} else {
    int  STB_TEXTEDIT_MOVEWORDRIGHT_IMPL(ImGuiInputTextState* obj, int idx)  { idx++; int len = obj.CurLenW; while (idx < len && !is_word_boundary_from_right(obj, idx)) idx++; return idx > len ? len : idx; }
}
alias STB_TEXTEDIT_MOVEWORDLEFT   = STB_TEXTEDIT_MOVEWORDLEFT_IMPL;    // They need to be #define for stb_textedit.h
alias STB_TEXTEDIT_MOVEWORDRIGHT  = STB_TEXTEDIT_MOVEWORDRIGHT_IMPL;

void STB_TEXTEDIT_DELETECHARS(ImGuiInputTextState* obj, int pos, int n)
{
    ImWchar* dst = obj.TextW.Data + pos;

    // We maintain our buffer length in both UTF-8 and wchar formats
    obj.Edited = true;
    obj.CurLenA -= ImTextCountUtf8BytesFromStr(dst, dst + n);
    obj.CurLenW -= n;

    // Offset remaining text (FIXME-OPT: Use memmove)
    const (ImWchar)* src = obj.TextW.Data + pos + n;
    ImWchar c = *src++;
    while (c) {
        *dst++ = c;
        c = *src++;
    }
    *dst = '\0';
}

bool STB_TEXTEDIT_INSERTCHARS(ImGuiInputTextState* obj, int pos, const ImWchar* new_text, int new_text_len)
{
    const bool is_resizable = (obj.Flags & ImGuiInputTextFlags.CallbackResize) != 0;
    const int text_len = obj.CurLenW;
    IM_ASSERT(pos <= text_len);

    const int new_text_len_utf8 = ImTextCountUtf8BytesFromStr(new_text, new_text + new_text_len);
    if (!is_resizable && (new_text_len_utf8 + obj.CurLenA + 1 > obj.BufCapacityA))
        return false;

    // Grow internal buffer if needed
    if (new_text_len + text_len + 1 > obj.TextW.Size)
    {
        if (!is_resizable)
            return false;
        IM_ASSERT(text_len < obj.TextW.Size);
        obj.TextW.resize(text_len + ImClamp(new_text_len * 4, 32, ImMax(256, new_text_len)) + 1);
    }

    ImWchar[] text = obj.TextW.asArray();
    if (pos != text_len)
        memmove(text.ptr + pos + new_text_len, text.ptr + pos, cast(size_t)(text_len - pos) * sizeof!(ImWchar));
    memcpy(text.ptr + pos, new_text, cast(size_t)new_text_len * sizeof!(ImWchar));

    obj.Edited = true;
    obj.CurLenW += new_text_len;
    obj.CurLenA += new_text_len_utf8;
    obj.TextW[obj.CurLenW] = '\0';

    return true;
}

// We don't use an enum so we can build even with conflicting symbols (if another user of stb_textedit.h leak their STB_TEXTEDIT_K_* symbols)
enum STB_TEXTEDIT_K_LEFT         = 0x200000; // keyboard input to move cursor left
enum STB_TEXTEDIT_K_RIGHT        = 0x200001; // keyboard input to move cursor right
enum STB_TEXTEDIT_K_UP           = 0x200002; // keyboard input to move cursor up
enum STB_TEXTEDIT_K_DOWN         = 0x200003; // keyboard input to move cursor down
enum STB_TEXTEDIT_K_LINESTART    = 0x200004; // keyboard input to move cursor to start of line
enum STB_TEXTEDIT_K_LINEEND      = 0x200005; // keyboard input to move cursor to end of line
enum STB_TEXTEDIT_K_TEXTSTART    = 0x200006; // keyboard input to move cursor to start of text
enum STB_TEXTEDIT_K_TEXTEND      = 0x200007; // keyboard input to move cursor to end of text
enum STB_TEXTEDIT_K_DELETE       = 0x200008; // keyboard input to delete selection or character under cursor
enum STB_TEXTEDIT_K_BACKSPACE    = 0x200009; // keyboard input to delete selection or character left of cursor
enum STB_TEXTEDIT_K_UNDO         = 0x20000A; // keyboard input to perform undo
enum STB_TEXTEDIT_K_REDO         = 0x20000B; // keyboard input to perform redo
enum STB_TEXTEDIT_K_WORDLEFT     = 0x20000C; // keyboard input to move cursor left one word
enum STB_TEXTEDIT_K_WORDRIGHT    = 0x20000D; // keyboard input to move cursor right one word
enum STB_TEXTEDIT_K_PGUP         = 0x20000E; // keyboard input to move cursor up a page
enum STB_TEXTEDIT_K_PGDOWN       = 0x20000F; // keyboard input to move cursor down a page
enum STB_TEXTEDIT_K_SHIFT        = 0x400000;

// #define STB_TEXTEDIT_IMPLEMENTATION
import d_imgui.imstb_textedit;

// stb_textedit internally allows for a single undo record to do addition and deletion, but somehow, calling
// the stb_textedit_paste() function creates two separate records, so we perform it manually. (FIXME: Report to nothings/stb?)
void stb_textedit_replace(ImGuiInputTextState* str, STB_TexteditState* state, const STB_TEXTEDIT_CHARTYPE* text, int text_len)
{
    stb_text_makeundo_replace(str, state, 0, str.CurLenW, text_len);
    STB_TEXTEDIT_DELETECHARS(str, 0, str.CurLenW);
    if (text_len <= 0)
        return;
    if (STB_TEXTEDIT_INSERTCHARS(str, 0, text, text_len))
    {
        state.cursor = text_len;
        state.has_preferred_x = 0;
        return;
    }
    IM_ASSERT(0); // Failed to insert character, normally shouldn't happen because of how we currently use stb_textedit_replace()
}

// } // namespace ImStb

// D_IMGUI: Wrapper for ImGuiInputTextState
struct ImGuiInputTextState_Wrapper {

    nothrow:
    @nogc:

    ImGuiInputTextState _data;
    alias _data this;

void OnKeyPressed(int key)
{
    stb_textedit_key(&this._data, &Stb, key);
    CursorFollow = true;
    CursorAnimReset();
}

}

// D_IMGUI: Wrapper for ImGuiInputTextCallbackData
struct ImGuiInputTextCallbackData_Wrapper {

    nothrow:
    @nogc:

    ImGuiInputTextCallbackData _data = ImGuiInputTextCallbackData.init;
    alias _data this;

this(bool dummy)
{
    memset(&this._data, 0, sizeof(this));
}

// Public API to manipulate UTF-8 text
// We expose UTF-8 to the user (unlike the STB_TEXTEDIT_* functions which are manipulating wchar)
// FIXME: The existence of this rarely exercised code path is a bit of a nuisance.
void DeleteChars(int pos, int bytes_count)
{
    IM_ASSERT(pos + bytes_count <= BufTextLen);
    size_t dst = pos;
    size_t src = pos + bytes_count;
    char c = Buf[src++];
    while (c) {
        Buf[dst++] = c;
        c = Buf[src++];
    }
    Buf[dst] = '\0';

    if (CursorPos >= pos + bytes_count)
        CursorPos -= bytes_count;
    else if (CursorPos >= pos)
        CursorPos = pos;
    SelectionStart = SelectionEnd = CursorPos;
    BufDirty = true;
    BufTextLen -= bytes_count;
}

void InsertChars(int pos, string new_text)
{
    const bool is_resizable = (Flags & ImGuiInputTextFlags.CallbackResize) != 0;
    const int new_text_len = cast(int)new_text.length;
    if (new_text_len + BufTextLen >= BufSize)
    {
        if (!is_resizable)
            return;

        // Contrary to STB_TEXTEDIT_INSERTCHARS() this is working in the UTF8 buffer, hence the mildly similar code (until we remove the U16 buffer altogether!)
        ImGuiContext* g = GImGui;
        ImGuiInputTextState* edit_state = &g.InputTextState;
        IM_ASSERT(edit_state.ID != 0 && g.ActiveId == edit_state.ID);
        IM_ASSERT(Buf.ptr == edit_state.TextA.Data);
        int new_buf_size = BufTextLen + ImClamp(new_text_len * 4, 32, ImMax(256, new_text_len)) + 1;
        edit_state.TextA.reserve(new_buf_size + 1);
        Buf = edit_state.TextA.asArray();
        BufSize = edit_state.BufCapacityA = new_buf_size;
    }

    if (BufTextLen != pos)
        memmove(Buf.ptr + pos + new_text_len, Buf.ptr + pos, cast(size_t)(BufTextLen - pos));
    memcpy(Buf.ptr + pos, new_text.ptr, cast(size_t)new_text_len * sizeof!(char));
    Buf[BufTextLen + new_text_len] = '\0';

    if (CursorPos >= pos)
        CursorPos += new_text_len;
    SelectionStart = SelectionEnd = CursorPos;
    BufDirty = true;
    BufTextLen += new_text_len;
}

}

// Return false to discard a character.
bool InputTextFilterCharacter(uint* p_char, ImGuiInputTextFlags flags, ImGuiInputTextCallback callback, void* user_data, ImGuiInputSource input_source)
{
    IM_ASSERT(input_source == ImGuiInputSource.Keyboard || input_source == ImGuiInputSource.Clipboard);
    uint c = *p_char;

    // Filter non-printable (NB: isprint is unreliable! see #2467)
    bool apply_named_filters = true;
    if (c < 0x20)
    {
        bool pass = false;
        pass |= (c == '\n' && (flags & ImGuiInputTextFlags.Multiline));
        pass |= (c == '\t' && (flags & ImGuiInputTextFlags.AllowTabInput));
        if (!pass)
            return false;
        apply_named_filters = false; // Override named filters below so newline and tabs can still be inserted.
    }

    if (input_source != ImGuiInputSource.Clipboard)
    {
        // We ignore Ascii representation of delete (emitted from Backspace on OSX, see #2578, #2817)
        if (c == 127)
            return false;

        // Filter private Unicode range. GLFW on OSX seems to send private characters for special keys like arrow keys (FIXME)
        if (c >= 0xE000 && c <= 0xF8FF)
            return false;
    }

    // Filter Unicode ranges we are not handling in this build
    if (c > IM_UNICODE_CODEPOINT_MAX)
        return false;

    // Generic named filters
    if (apply_named_filters && (flags & (ImGuiInputTextFlags.CharsDecimal | ImGuiInputTextFlags.CharsHexadecimal | ImGuiInputTextFlags.CharsUppercase | ImGuiInputTextFlags.CharsNoBlank | ImGuiInputTextFlags.CharsScientific)))
    {
        // The libc allows overriding locale, with e.g. 'setlocale(LC_NUMERIC, "de_DE.UTF-8");' which affect the output/input of printf/scanf.
        // The standard mandate that programs starts in the "C" locale where the decimal point is '.'.
        // We don't really intend to provide widespread support for it, but out of empathy for people stuck with using odd API, we support the bare minimum aka overriding the decimal point.
        // Change the default decimal_point with:
        //   ImGui::GetCurrentContext()->PlatformLocaleDecimalPoint = *localeconv()->decimal_point;
        ImGuiContext* g = GImGui;
        const uint c_decimal_point = cast(uint)g.PlatformLocaleDecimalPoint;

        // Allow 0-9 . - + * /
        if (flags & ImGuiInputTextFlags.CharsDecimal)
            if (!(c >= '0' && c <= '9') && (c != c_decimal_point) && (c != '-') && (c != '+') && (c != '*') && (c != '/'))
                return false;

        // Allow 0-9 . - + * / e E
        if (flags & ImGuiInputTextFlags.CharsScientific)
            if (!(c >= '0' && c <= '9') && (c != c_decimal_point) && (c != '-') && (c != '+') && (c != '*') && (c != '/') && (c != 'e') && (c != 'E'))
                return false;

        // Allow 0-9 a-F A-F
        if (flags & ImGuiInputTextFlags.CharsHexadecimal)
            if (!(c >= '0' && c <= '9') && !(c >= 'a' && c <= 'f') && !(c >= 'A' && c <= 'F'))
                return false;

        // Turn a-z into A-Z
        if (flags & ImGuiInputTextFlags.CharsUppercase)
            if (c >= 'a' && c <= 'z')
                *p_char = (c += cast(uint)('A' - 'a'));

        if (flags & ImGuiInputTextFlags.CharsNoBlank)
            if (ImCharIsBlankW(c))
                return false;
    }

    // Custom callback filter
    if (flags & ImGuiInputTextFlags.CallbackCharFilter)
    {
        ImGuiInputTextCallbackData callback_data;
        memset(&callback_data, 0, sizeof!(ImGuiInputTextCallbackData));
        callback_data.EventFlag = ImGuiInputTextFlags.CallbackCharFilter;
        callback_data.EventChar = cast(ImWchar)c;
        callback_data.Flags = flags;
        callback_data.UserData = user_data;
        if (callback(&callback_data) != 0)
            return false;
        *p_char = callback_data.EventChar;
        if (!callback_data.EventChar)
            return false;
    }

    return true;
}

// Edit a string of text
// - buf_size account for the zero-terminator, so a buf_size of 6 can hold "Hello" but not "Hello!".
//   This is so we can easily call InputText() on static arrays using ARRAYSIZE() and to match
//   Note that in std::string world, capacity() would omit 1 byte used by the zero-terminator.
// - When active, hold on a privately held copy of the text (and apply back to 'buf'). So changing 'buf' while the InputText is active has no effect.
// - If you want to use ImGui::InputText() with std::string, see misc/cpp/imgui_stdlib.h
// (FIXME: Rather confusing and messy function, among the worse part of our codebase, expecting to rewrite a V2 at some point.. Partly because we are
//  doing UTF8 > U16 > UTF8 conversions on the go to easily interface with stb_textedit. Ideally should stay in UTF-8 all the time. See https://github.com/nothings/stb/issues/188)
bool InputTextEx(string label, string hint, char[] buf, const ImVec2/*&*/ size_arg, ImGuiInputTextFlags flags, ImGuiInputTextCallback callback = NULL, void* callback_user_data = NULL)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    IM_ASSERT(buf.ptr != NULL && buf.length >= 0);
    IM_ASSERT(!((flags & ImGuiInputTextFlags.CallbackHistory) && (flags & ImGuiInputTextFlags.Multiline)));        // Can't use both together (they both use up/down keys)
    IM_ASSERT(!((flags & ImGuiInputTextFlags.CallbackCompletion) && (flags & ImGuiInputTextFlags.AllowTabInput))); // Can't use both together (they both use tab key)

    ImGuiContext* g = GImGui;
    ImGuiIO* io = &g.IO;
    const ImGuiStyle* style = &g.Style;

    const bool RENDER_SELECTION_WHEN_INACTIVE = false;
    const bool is_multiline = (flags & ImGuiInputTextFlags.Multiline) != 0;
    const bool is_readonly = (flags & ImGuiInputTextFlags.ReadOnly) != 0;
    const bool is_password = (flags & ImGuiInputTextFlags.Password) != 0;
    const bool is_undoable = (flags & ImGuiInputTextFlags.NoUndoRedo) == 0;
    const bool is_resizable = (flags & ImGuiInputTextFlags.CallbackResize) != 0;
    if (is_resizable)
        IM_ASSERT(callback != NULL); // Must provide a callback if you set the ImGuiInputTextFlags.CallbackResize flag!

    if (is_multiline) // Open group before calling GetID() because groups tracks id created within their scope,
        BeginGroup();
    const ImGuiID id = window.GetID(label);
    const ImVec2 label_size = CalcTextSize(label, true);
    const ImVec2 frame_size = CalcItemSize(size_arg, CalcItemWidth(), (is_multiline ? g.FontSize * 8.0f : label_size.y) + style.FramePadding.y * 2.0f); // Arbitrary default of 8 lines high for multi-line
    const ImVec2 total_size = ImVec2(frame_size.x + (label_size.x > 0.0f ? style.ItemInnerSpacing.x + label_size.x : 0.0f), frame_size.y);

    const ImRect frame_bb = ImRect(window.DC.CursorPos, window.DC.CursorPos + frame_size);
    const ImRect total_bb = ImRect(frame_bb.Min, frame_bb.Min + total_size);

    ImGuiWindow* draw_window = window;
    ImVec2 inner_size = frame_size;
    ImGuiItemStatusFlags item_status_flags = ImGuiItemStatusFlags.None;
    if (is_multiline)
    {
        if (!ItemAdd(total_bb, id, &frame_bb, ImGuiItemAddFlags.Focusable))
        {
            ItemSize(total_bb, style.FramePadding.y);
            EndGroup();
            return false;
        }
        item_status_flags = g.LastItemData.StatusFlags;

        // We reproduce the contents of BeginChildFrame() in order to provide 'label' so our window internal data are easier to read/debug.
        PushStyleColor(ImGuiCol.ChildBg, style.Colors[ImGuiCol.FrameBg]);
        PushStyleVar(ImGuiStyleVar.ChildRounding, style.FrameRounding);
        PushStyleVar(ImGuiStyleVar.ChildBorderSize, style.FrameBorderSize);
        bool child_visible = BeginChildEx(label, id, frame_bb.GetSize(), true, ImGuiWindowFlags.NoMove);
        PopStyleVar(2);
        PopStyleColor();
        if (!child_visible)
        {
            EndChild();
            EndGroup();
            return false;
        }
        draw_window = g.CurrentWindow; // Child window
        draw_window.DC.NavLayersActiveMaskNext |= (1 << draw_window.DC.NavLayerCurrent); // This is to ensure that EndChild() will display a navigation highlight so we can "enter" into it.
        draw_window.DC.CursorPos += style.FramePadding;
        inner_size.x -= draw_window.ScrollbarSizes.x;
    }
    else
    {
        // Support for internal ImGuiInputTextFlags_MergedItem flag, which could be redesigned as an ItemFlags if needed (with test performed in ItemAdd)
        ItemSize(total_bb, style.FramePadding.y);
        if (!(flags & ImGuiInputTextFlags.MergedItem))
            if (!ItemAdd(total_bb, id, &frame_bb, ImGuiItemAddFlags.Focusable))
                return false;
        item_status_flags = g.LastItemData.StatusFlags;
    }
    const bool hovered = ItemHoverable(frame_bb, id);
    if (hovered)
        g.MouseCursor = ImGuiMouseCursor.TextInput;

    // We are only allowed to access the state if we are already the active widget.
    ImGuiInputTextState* state = GetInputTextState(id);

    const bool focus_requested_by_code = (item_status_flags & ImGuiItemStatusFlags.FocusedByCode) != 0;
    const bool focus_requested_by_tabbing = (item_status_flags & ImGuiItemStatusFlags.FocusedByTabbing) != 0;

    const bool user_clicked = hovered && io.MouseClicked[0];
    const bool user_nav_input_start = (g.ActiveId != id) && ((g.NavInputId == id) || (g.NavActivateId == id && g.NavInputSource == ImGuiInputSource.Keyboard));
    const bool user_scroll_finish = is_multiline && state != NULL && g.ActiveId == 0 && g.ActiveIdPreviousFrame == GetWindowScrollbarID(draw_window, ImGuiAxis.Y);
    const bool user_scroll_active = is_multiline && state != NULL && g.ActiveId == GetWindowScrollbarID(draw_window, ImGuiAxis.Y);

    bool clear_active_id = false;
    bool select_all = (g.ActiveId != id) && ((flags & ImGuiInputTextFlags.AutoSelectAll) != 0 || user_nav_input_start) && (!is_multiline);

    float scroll_y = is_multiline ? draw_window.Scroll.y : FLT_MAX;

    const bool init_changed_specs = (state != NULL && state.Stb.single_line != !is_multiline);
    const bool init_make_active = (user_clicked || user_scroll_finish || user_nav_input_start || focus_requested_by_code || focus_requested_by_tabbing);
    const bool init_state = (init_make_active || user_scroll_active);
    if ((init_state && g.ActiveId != id) || init_changed_specs)
    {
        // Access state even if we don't own it yet.
        state = &g.InputTextState;
        state.CursorAnimReset();

        // Take a copy of the initial buffer value (both in original UTF-8 format and converted to wchar)
        // From the moment we focused we are ignoring the content of 'buf' (unless we are in read-only mode)
        const int buf_len = cast(int)strlen(buf);
        state.InitialTextA.resize(buf_len + 1);    // UTF-8. we use +1 to make sure that .Data is always pointing to at least an empty string.
        memcpy(state.InitialTextA.asArray(), buf, buf_len + 1);

        // Start edition
        string buf_end = NULL;
        state.TextW.resize(cast(int)buf.length + 1);          // wchar count <= UTF-8 count. we use +1 to make sure that .Data is always pointing to at least an empty string.
        state.TextA.resize(0);
        state.TextAIsValid = false;                // TextA is not valid yet (we will display buf until then)
        state.CurLenW = ImTextStrFromUtf8(state.TextW.Data, cast(int)buf.length, cast(string)buf[0..buf_len], &buf_end);
        state.CurLenA = cast(int)(buf_end.ptr - buf.ptr);      // We can't get the result from ImStrncpy() above because it is not UTF-8 aware. Here we'll cut off malformed UTF-8.

        // Preserve cursor position and undo/redo stack if we come back to same widget
        // FIXME: For non-readonly widgets we might be able to require that TextAIsValid && TextA == buf ? (untested) and discard undo stack if user buffer has changed.
        const bool recycle_state = (state.ID == id && !init_changed_specs);
        if (recycle_state)
        {
            // Recycle existing cursor/selection/undo stack but clamp position
            // Note a single mouse click will override the cursor/position immediately by calling stb_textedit_click handler.
            state.CursorClamp();
        }
        else
        {
            state.ID = id;
            state.ScrollX = 0.0f;
            stb_textedit_initialize_state(&state.Stb, !is_multiline);
            if (!is_multiline && focus_requested_by_code)
                select_all = true;
        }
        if (flags & ImGuiInputTextFlags.AlwaysOverwrite)
            state.Stb.insert_mode = 1; // stb field name is indeed incorrect (see #2863)
        if (!is_multiline && (focus_requested_by_tabbing || (user_clicked && io.KeyCtrl)))
            select_all = true;
    }

    if (g.ActiveId != id && init_make_active)
    {
        IM_ASSERT(state && state.ID == id);
        SetActiveID(id, window);
        SetFocusID(id, window);
        FocusWindow(window);

        // Declare our inputs
        IM_ASSERT(ImGuiNavInput.COUNT < 32);
        g.ActiveIdUsingNavDirMask |= (1 << ImGuiDir.Left) | (1 << ImGuiDir.Right);
        if (is_multiline || (flags & ImGuiInputTextFlags.CallbackHistory))
            g.ActiveIdUsingNavDirMask |= (1 << ImGuiDir.Up) | (1 << ImGuiDir.Down);
        g.ActiveIdUsingNavInputMask |= (1 << ImGuiNavInput.Cancel);
        g.ActiveIdUsingKeyInputMask |= (cast(ImU64)1 << ImGuiKey.Home) | (cast(ImU64)1 << ImGuiKey.End);
        if (is_multiline)
            g.ActiveIdUsingKeyInputMask |= (cast(ImU64)1 << ImGuiKey.PageUp) | (cast(ImU64)1 << ImGuiKey.PageDown);
        if (flags & (ImGuiInputTextFlags.CallbackCompletion | ImGuiInputTextFlags.AllowTabInput))  // Disable keyboard tabbing out as we will use the \t character.
            g.ActiveIdUsingKeyInputMask |= (cast(ImU64)1 << ImGuiKey.Tab);
    }

    // We have an edge case if ActiveId was set through another widget (e.g. widget being swapped), clear id immediately (don't wait until the end of the function)
    if (g.ActiveId == id && state == NULL)
        ClearActiveID();

    // Release focus when we click outside
    if (g.ActiveId == id && io.MouseClicked[0] && !init_state && !init_make_active) //-V560
        clear_active_id = true;

    // Lock the decision of whether we are going to take the path displaying the cursor or selection
    const bool render_cursor = (g.ActiveId == id) || (state && user_scroll_active);
    bool render_selection = state && state.HasSelection() && (RENDER_SELECTION_WHEN_INACTIVE || render_cursor);
    bool value_changed = false;
    bool enter_pressed = false;

    // When read-only we always use the live data passed to the function
    // FIXME-OPT: Because our selection/cursor code currently needs the wide text we need to convert it when active, which is not ideal :(
    if (is_readonly && state != NULL && (render_cursor || render_selection))
    {
        string buf_end = NULL;
        state.TextW.resize(cast(int)buf.length + 1);
        state.CurLenW = ImTextStrFromUtf8(state.TextW.Data, state.TextW.Size, ImCstring(buf), &buf_end);
        state.CurLenA = cast(int)(buf_end.ptr - buf.ptr);
        state.CursorClamp();
        render_selection &= state.HasSelection();
    }

    // Select the buffer to render.
    const bool buf_display_from_state = (render_cursor || render_selection || g.ActiveId == id) && !is_readonly && state && state.TextAIsValid;
    const bool is_displaying_hint = (hint != NULL && (buf_display_from_state ? state.TextA.Data : buf.ptr)[0] == 0);

    // Password pushes a temporary font with only a fallback glyph
    if (is_password && !is_displaying_hint)
    {
        const ImFontGlyph* glyph = g.Font.FindGlyph('*');
        ImFont* password_font = &g.InputTextPasswordFont;
        password_font.FontSize = g.Font.FontSize;
        password_font.Scale = g.Font.Scale;
        password_font.Ascent = g.Font.Ascent;
        password_font.Descent = g.Font.Descent;
        password_font.ContainerAtlas = g.Font.ContainerAtlas;
        password_font.FallbackGlyph = glyph;
        password_font.FallbackAdvanceX = glyph.AdvanceX;
        IM_ASSERT(password_font.Glyphs.empty() && password_font.IndexAdvanceX.empty() && password_font.IndexLookup.empty());
        PushFont(password_font);
    }

    // Process mouse inputs and character inputs
    int backup_current_text_length = 0;
    if (g.ActiveId == id)
    {
        IM_ASSERT(state != NULL);
        backup_current_text_length = state.CurLenA;
        state.Edited = false;
        state.BufCapacityA = cast(int)buf.length;
        state.Flags = flags;
        state.UserCallback = callback;
        state.UserCallbackData = callback_user_data;

        // Although we are active we don't prevent mouse from hovering other elements unless we are interacting right now with the widget.
        // Down the line we should have a cleaner library-wide concept of Selected vs Active.
        g.ActiveIdAllowOverlap = !io.MouseDown[0];
        g.WantTextInputNextFrame = 1;

        // Edit in progress
        const float mouse_x = (io.MousePos.x - frame_bb.Min.x - style.FramePadding.x) + state.ScrollX;
        const float mouse_y = (is_multiline ? (io.MousePos.y - draw_window.DC.CursorPos.y) : (g.FontSize * 0.5f));

        const bool is_osx = io.ConfigMacOSXBehaviors;
        if (select_all || (hovered && !is_osx && io.MouseDoubleClicked[0]))
        {
            state.SelectAll();
            state.SelectedAllMouseLock = true;
        }
        else if (hovered && is_osx && io.MouseDoubleClicked[0])
        {
            // Double-click select a word only, OS X style (by simulating keystrokes)
            state.OnKeyPressed(STB_TEXTEDIT_K_WORDLEFT);
            state.OnKeyPressed(STB_TEXTEDIT_K_WORDRIGHT | STB_TEXTEDIT_K_SHIFT);
        }
        else if (io.MouseClicked[0] && !state.SelectedAllMouseLock)
        {
            if (hovered)
            {
                stb_textedit_click(state, &state.Stb, mouse_x, mouse_y);
                state.CursorAnimReset();
            }
        }
        else if (io.MouseDown[0] && !state.SelectedAllMouseLock && (io.MouseDelta.x != 0.0f || io.MouseDelta.y != 0.0f))
        {
            stb_textedit_drag(state, &state.Stb, mouse_x, mouse_y);
            state.CursorAnimReset();
            state.CursorFollow = true;
        }
        if (state.SelectedAllMouseLock && !io.MouseDown[0])
            state.SelectedAllMouseLock = false;

        // It is ill-defined whether the backend needs to send a \t character when pressing the TAB keys.
        // Win32 and GLFW naturally do it but not SDL.
        const bool ignore_char_inputs = (io.KeyCtrl && !io.KeyAlt) || (is_osx && io.KeySuper);
        if ((flags & ImGuiInputTextFlags.AllowTabInput) && IsKeyPressedMap(ImGuiKey.Tab) && !ignore_char_inputs && !io.KeyShift && !is_readonly)
            if (!io.InputQueueCharacters.contains('\t'))
            {
                uint c = '\t'; // Insert TAB
                if (InputTextFilterCharacter(&c, flags, callback, callback_user_data, ImGuiInputSource.Keyboard))
                    state.OnKeyPressed(cast(int)c);
            }

        // Process regular text input (before we check for Return because using some IME will effectively send a Return?)
        // We ignore CTRL inputs, but need to allow ALT+CTRL as some keyboards (e.g. German) use AltGR (which _is_ Alt+Ctrl) to input certain characters.
        if (io.InputQueueCharacters.Size > 0)
        {
            if (!ignore_char_inputs && !is_readonly && !user_nav_input_start)
                for (int n = 0; n < io.InputQueueCharacters.Size; n++)
                {
                    // Insert character if they pass filtering
                    uint c = cast(uint)io.InputQueueCharacters[n];
                    if (c == '\t' && io.KeyShift)
                        continue;
                    if (InputTextFilterCharacter(&c, flags, callback, callback_user_data, ImGuiInputSource.Keyboard))
                        state.OnKeyPressed(cast(int)c);
                }

            // Consume characters
            io.InputQueueCharacters.resize(0);
        }
    }

    // Process other shortcuts/key-presses
    bool cancel_edit = false;
    if (g.ActiveId == id && !g.ActiveIdIsJustActivated && !clear_active_id)
    {
        IM_ASSERT(state != NULL);
        IM_ASSERT(io.KeyMods == GetMergedKeyModFlags(), "Mismatching io.KeyCtrl/io.KeyShift/io.KeyAlt/io.KeySuper vs io.KeyMods"); // We rarely do this check, but if anything let's do it here.

        const int row_count_per_page = ImMax(cast(int)((inner_size.y - style.FramePadding.y) / g.FontSize), 1);
        state.Stb.row_count_per_page = row_count_per_page;

        const int k_mask = (io.KeyShift ? STB_TEXTEDIT_K_SHIFT : 0);
        const bool is_osx = io.ConfigMacOSXBehaviors;
        const bool is_osx_shift_shortcut = is_osx && (io.KeyMods == (ImGuiKeyModFlags.Super | ImGuiKeyModFlags.Shift));
        const bool is_wordmove_key_down = is_osx ? io.KeyAlt : io.KeyCtrl;                     // OS X style: Text editing cursor movement using Alt instead of Ctrl
        const bool is_startend_key_down = is_osx && io.KeySuper && !io.KeyCtrl && !io.KeyAlt;  // OS X style: Line/Text Start and End using Cmd+Arrows instead of Home/End
        const bool is_ctrl_key_only = (io.KeyMods == ImGuiKeyModFlags.Ctrl);
        const bool is_shift_key_only = (io.KeyMods == ImGuiKeyModFlags.Shift);
        const bool is_shortcut_key = g.IO.ConfigMacOSXBehaviors ? (io.KeyMods == ImGuiKeyModFlags.Super) : (io.KeyMods == ImGuiKeyModFlags.Ctrl);

        const bool is_cut   = ((is_shortcut_key && IsKeyPressedMap(ImGuiKey.X)) || (is_shift_key_only && IsKeyPressedMap(ImGuiKey.Delete))) && !is_readonly && !is_password && (!is_multiline || state.HasSelection());
        const bool is_copy  = ((is_shortcut_key && IsKeyPressedMap(ImGuiKey.C)) || (is_ctrl_key_only  && IsKeyPressedMap(ImGuiKey.Insert))) && !is_password && (!is_multiline || state.HasSelection());
        const bool is_paste = ((is_shortcut_key && IsKeyPressedMap(ImGuiKey.V)) || (is_shift_key_only && IsKeyPressedMap(ImGuiKey.Insert))) && !is_readonly;
        const bool is_undo  = ((is_shortcut_key && IsKeyPressedMap(ImGuiKey.Z)) && !is_readonly && is_undoable);
        const bool is_redo  = ((is_shortcut_key && IsKeyPressedMap(ImGuiKey.Y)) || (is_osx_shift_shortcut && IsKeyPressedMap(ImGuiKey.Z))) && !is_readonly && is_undoable;

        if (IsKeyPressedMap(ImGuiKey.LeftArrow))                        { state.OnKeyPressed((is_startend_key_down ? STB_TEXTEDIT_K_LINESTART : is_wordmove_key_down ? STB_TEXTEDIT_K_WORDLEFT : STB_TEXTEDIT_K_LEFT) | k_mask); }
        else if (IsKeyPressedMap(ImGuiKey.RightArrow))                  { state.OnKeyPressed((is_startend_key_down ? STB_TEXTEDIT_K_LINEEND : is_wordmove_key_down ? STB_TEXTEDIT_K_WORDRIGHT : STB_TEXTEDIT_K_RIGHT) | k_mask); }
        else if (IsKeyPressedMap(ImGuiKey.UpArrow) && is_multiline)     { if (io.KeyCtrl) SetScrollY(draw_window, ImMax(draw_window.Scroll.y - g.FontSize, 0.0f)); else state.OnKeyPressed((is_startend_key_down ? STB_TEXTEDIT_K_TEXTSTART : STB_TEXTEDIT_K_UP) | k_mask); }
        else if (IsKeyPressedMap(ImGuiKey.DownArrow) && is_multiline)   { if (io.KeyCtrl) SetScrollY(draw_window, ImMin(draw_window.Scroll.y + g.FontSize, GetScrollMaxY())); else state.OnKeyPressed((is_startend_key_down ? STB_TEXTEDIT_K_TEXTEND : STB_TEXTEDIT_K_DOWN) | k_mask); }
        else if (IsKeyPressedMap(ImGuiKey.PageUp) && is_multiline)      { state.OnKeyPressed(STB_TEXTEDIT_K_PGUP | k_mask); scroll_y -= row_count_per_page * g.FontSize; }
        else if (IsKeyPressedMap(ImGuiKey.PageDown) && is_multiline)    { state.OnKeyPressed(STB_TEXTEDIT_K_PGDOWN | k_mask); scroll_y += row_count_per_page * g.FontSize; }
        else if (IsKeyPressedMap(ImGuiKey.Home))                        { state.OnKeyPressed(io.KeyCtrl ? STB_TEXTEDIT_K_TEXTSTART | k_mask : STB_TEXTEDIT_K_LINESTART | k_mask); }
        else if (IsKeyPressedMap(ImGuiKey.End))                         { state.OnKeyPressed(io.KeyCtrl ? STB_TEXTEDIT_K_TEXTEND | k_mask : STB_TEXTEDIT_K_LINEEND | k_mask); }
        else if (IsKeyPressedMap(ImGuiKey.Delete) && !is_readonly)      { state.OnKeyPressed(STB_TEXTEDIT_K_DELETE | k_mask); }
        else if (IsKeyPressedMap(ImGuiKey.Backspace) && !is_readonly)
        {
            if (!state.HasSelection())
            {
                if (is_wordmove_key_down)
                    state.OnKeyPressed(STB_TEXTEDIT_K_WORDLEFT | STB_TEXTEDIT_K_SHIFT);
                else if (is_osx && io.KeySuper && !io.KeyAlt && !io.KeyCtrl)
                    state.OnKeyPressed(STB_TEXTEDIT_K_LINESTART | STB_TEXTEDIT_K_SHIFT);
            }
            state.OnKeyPressed(STB_TEXTEDIT_K_BACKSPACE | k_mask);
        }
        else if (IsKeyPressedMap(ImGuiKey.Enter) || IsKeyPressedMap(ImGuiKey.KeyPadEnter))
        {
            bool ctrl_enter_for_new_line = (flags & ImGuiInputTextFlags.CtrlEnterForNewLine) != 0;
            if (!is_multiline || (ctrl_enter_for_new_line && !io.KeyCtrl) || (!ctrl_enter_for_new_line && io.KeyCtrl))
            {
                enter_pressed = clear_active_id = true;
            }
            else if (!is_readonly)
            {
                uint c = '\n'; // Insert new line
                if (InputTextFilterCharacter(&c, flags, callback, callback_user_data, ImGuiInputSource.Keyboard))
                    state.OnKeyPressed(cast(int)c);
            }
        }
        else if (IsKeyPressedMap(ImGuiKey.Escape))
        {
            clear_active_id = cancel_edit = true;
        }
        else if (is_undo || is_redo)
        {
            state.OnKeyPressed(is_undo ? STB_TEXTEDIT_K_UNDO : STB_TEXTEDIT_K_REDO);
            state.ClearSelection();
        }
        else if (is_shortcut_key && IsKeyPressedMap(ImGuiKey.A))
        {
            state.SelectAll();
            state.CursorFollow = true;
        }
        else if (is_cut || is_copy)
        {
            // Cut, Copy
            if (io.SetClipboardTextFn)
            {
                const int ib = state.HasSelection() ? ImMin(state.Stb.select_start, state.Stb.select_end) : 0;
                const int ie = state.HasSelection() ? ImMax(state.Stb.select_start, state.Stb.select_end) : state.CurLenW;
                const int clipboard_data_len = ImTextCountUtf8BytesFromStr(state.TextW.Data + ib, state.TextW.Data + ie) + 1;
                char[] clipboard_data = IM_ALLOC!char(clipboard_data_len * sizeof!(char));
                int length = ImTextStrToUtf8(clipboard_data.ptr, clipboard_data_len, state.TextW.Data + ib, state.TextW.Data + ie);
                SetClipboardText(cast(string)clipboard_data[0..length]);
                MemFree(clipboard_data);
            }
            if (is_cut)
            {
                if (!state.HasSelection())
                    state.SelectAll();
                state.CursorFollow = true;
                stb_textedit_cut(state, &state.Stb);
            }
        }
        else if (is_paste)
        {
            if (string clipboard = GetClipboardText())
            {
                // Filter pasted buffer
                const int clipboard_len = cast(int)clipboard.length;
                ImWchar[] clipboard_filtered = IM_ALLOC!ImWchar(clipboard_len + 1);
                int clipboard_filtered_len = 0;
                for (size_t s = 0; s < clipboard.length; )
                {
                    uint c;
                    s += ImTextCharFromUtf8(&c, clipboard[s..$]);
                    if (c == 0)
                        break;
                    if (!InputTextFilterCharacter(&c, flags, callback, callback_user_data, ImGuiInputSource.Clipboard))
                        continue;
                    clipboard_filtered[clipboard_filtered_len++] = cast(ImWchar)c;
                }
                clipboard_filtered[clipboard_filtered_len] = 0;
                if (clipboard_filtered_len > 0) // If everything was filtered, ignore the pasting operation
                {
                    stb_textedit_paste(state, &state.Stb, clipboard_filtered.ptr, clipboard_filtered_len);
                    state.CursorFollow = true;
                }
                MemFree(clipboard_filtered);
            }
        }

        // Update render selection flag after events have been handled, so selection highlight can be displayed during the same frame.
        render_selection |= state.HasSelection() && (RENDER_SELECTION_WHEN_INACTIVE || render_cursor);
    }

    // Process callbacks and apply result back to user's buffer.
    if (g.ActiveId == id)
    {
        IM_ASSERT(state != NULL);
        string apply_new_text = NULL;
        int apply_new_text_length = 0;
        if (cancel_edit)
        {
            // Restore initial value. Only return true if restoring to the initial value changes the current buffer contents.
            if (!is_readonly && strcmp(buf, state.InitialTextA.asArray()) != 0)
            {
                // Push records into the undo stack so we can CTRL+Z the revert operation itself
                apply_new_text = cast(string)state.InitialTextA.asArray();
                apply_new_text_length = state.InitialTextA.Size;
                ImVector!ImWchar w_text;
                scope (exit) w_text.destroy();
                if (apply_new_text_length > 0)
                {
                    w_text.resize(ImTextCountCharsFromUtf8(apply_new_text) + 1);
                    ImTextStrFromUtf8(w_text.Data, w_text.Size, apply_new_text);
                }
                stb_textedit_replace(state, &state.Stb, w_text.Data, (apply_new_text_length > 0) ? (w_text.Size - 1) : 0);
            }
        }

        // When using 'ImGuiInputTextFlags_EnterReturnsTrue' as a special case we reapply the live buffer back to the input buffer before clearing ActiveId, even though strictly speaking it wasn't modified on this frame.
        // If we didn't do that, code like InputInt() with ImGuiInputTextFlags_EnterReturnsTrue would fail.
        // This also allows the user to use InputText() with ImGuiInputTextFlags_EnterReturnsTrue without maintaining any user-side storage (please note that if you use this property along ImGuiInputTextFlags_CallbackResize you can end up with your temporary string object unnecessarily allocating once a frame, either store your string data, either if you don't then don't use ImGuiInputTextFlags_CallbackResize).
        bool apply_edit_back_to_user_buffer = !cancel_edit || (enter_pressed && (flags & ImGuiInputTextFlags.EnterReturnsTrue) != 0);
        if (apply_edit_back_to_user_buffer)
        {
            // Apply new value immediately - copy modified buffer back
            // Note that as soon as the input box is active, the in-widget value gets priority over any underlying modification of the input buffer
            // FIXME: We actually always render 'buf' when calling DrawList->AddText, making the comment above incorrect.
            // FIXME-OPT: CPU waste to do this every time the widget is active, should mark dirty state from the stb_textedit callbacks.
            if (!is_readonly)
            {
                state.TextAIsValid = true;
                state.TextA.resize(state.TextW.Size * 4 + 1);
                ImTextStrToUtf8(state.TextA.Data, state.TextA.Size, state.TextW.Data, NULL);
            }

            // User callback
            if ((flags & (ImGuiInputTextFlags.CallbackCompletion | ImGuiInputTextFlags.CallbackHistory | ImGuiInputTextFlags.CallbackEdit | ImGuiInputTextFlags.CallbackAlways)) != 0)
            {
                IM_ASSERT(callback != NULL);

                // The reason we specify the usage semantic (Completion/History) is that Completion needs to disable keyboard TABBING at the moment.
                ImGuiInputTextFlags event_flag = ImGuiInputTextFlags.None;
                ImGuiKey event_key = ImGuiKey.COUNT;
                if ((flags & ImGuiInputTextFlags.CallbackCompletion) != 0 && IsKeyPressedMap(ImGuiKey.Tab))
                {
                    event_flag = ImGuiInputTextFlags.CallbackCompletion;
                    event_key = ImGuiKey.Tab;
                }
                else if ((flags & ImGuiInputTextFlags.CallbackHistory) != 0 && IsKeyPressedMap(ImGuiKey.UpArrow))
                {
                    event_flag = ImGuiInputTextFlags.CallbackHistory;
                    event_key = ImGuiKey.UpArrow;
                }
                else if ((flags & ImGuiInputTextFlags.CallbackHistory) != 0 && IsKeyPressedMap(ImGuiKey.DownArrow))
                {
                    event_flag = ImGuiInputTextFlags.CallbackHistory;
                    event_key = ImGuiKey.DownArrow;
                }
                else if ((flags & ImGuiInputTextFlags.CallbackEdit) && state.Edited)
                {
                    event_flag = ImGuiInputTextFlags.CallbackEdit;
                }
                else if (flags & ImGuiInputTextFlags.CallbackAlways)
                {
                    event_flag = ImGuiInputTextFlags.CallbackAlways;
                }

                if (event_flag)
                {
                    ImGuiInputTextCallbackData callback_data;
                    memset(&callback_data, 0, sizeof!(ImGuiInputTextCallbackData));
                    callback_data.EventFlag = event_flag;
                    callback_data.Flags = flags;
                    callback_data.UserData = callback_user_data;

                    callback_data.EventKey = event_key;
                    callback_data.Buf = state.TextA.asArray();
                    callback_data.BufTextLen = state.CurLenA;
                    callback_data.BufSize = state.BufCapacityA;
                    callback_data.BufDirty = false;

                    // We have to convert from wchar-positions to UTF-8-positions, which can be pretty slow (an incentive to ditch the ImWchar buffer, see https://github.com/nothings/stb/issues/188)
                    ImWchar* text = state.TextW.Data;
                    const int utf8_cursor_pos = callback_data.CursorPos = ImTextCountUtf8BytesFromStr(text, text + state.Stb.cursor);
                    const int utf8_selection_start = callback_data.SelectionStart = ImTextCountUtf8BytesFromStr(text, text + state.Stb.select_start);
                    const int utf8_selection_end = callback_data.SelectionEnd = ImTextCountUtf8BytesFromStr(text, text + state.Stb.select_end);

                    // Call user code
                    callback(&callback_data);

                    // Read back what user may have modified
                    IM_ASSERT(callback_data.Buf.ptr == state.TextA.Data);  // Invalid to modify those fields
                    IM_ASSERT(callback_data.BufSize == state.BufCapacityA);
                    IM_ASSERT(callback_data.Flags == flags);
                    const bool buf_dirty = callback_data.BufDirty;
                    if (callback_data.CursorPos != utf8_cursor_pos || buf_dirty)            { state.Stb.cursor = ImTextCountCharsFromUtf8(cast(string)callback_data.Buf[0..callback_data.CursorPos]); state.CursorFollow = true; }
                    if (callback_data.SelectionStart != utf8_selection_start || buf_dirty)  { state.Stb.select_start = (callback_data.SelectionStart == callback_data.CursorPos) ? state.Stb.cursor : ImTextCountCharsFromUtf8(cast(string)callback_data.Buf[0..callback_data.SelectionStart]); }
                    if (callback_data.SelectionEnd != utf8_selection_end || buf_dirty)      { state.Stb.select_end = (callback_data.SelectionEnd == callback_data.SelectionStart) ? state.Stb.select_start : ImTextCountCharsFromUtf8(cast(string)callback_data.Buf[0..callback_data.SelectionEnd]); }
                    if (buf_dirty)
                    {
                        IM_ASSERT(callback_data.BufTextLen == cast(int)strlen(callback_data.Buf)); // You need to maintain BufTextLen if you change the text!
                        if (callback_data.BufTextLen > backup_current_text_length && is_resizable)
                            state.TextW.resize(state.TextW.Size + (callback_data.BufTextLen - backup_current_text_length));
                        state.CurLenW = ImTextStrFromUtf8(state.TextW.Data, state.TextW.Size, cast(string)callback_data.Buf[0..callback_data.BufTextLen]);
                        state.CurLenA = callback_data.BufTextLen;  // Assume correct length and valid UTF-8 from user, saves us an extra strlen()
                        state.CursorAnimReset();
                    }
                }
            }

            // Will copy result string if modified
            if (!is_readonly && strcmp(state.TextA.asArray(), buf) != 0)
            {
                apply_new_text = cast(string)state.TextA.asArray();
                apply_new_text_length = state.CurLenA;
            }
        }

        // Copy result to user buffer
        if (apply_new_text !is NULL)
        {
            // We cannot test for 'backup_current_text_length != apply_new_text_length' here because we have no guarantee that the size
            // of our owned buffer matches the size of the string object held by the user, and by design we allow InputText() to be used
            // without any storage on user's side.
            IM_ASSERT(apply_new_text_length >= 0);
            if (is_resizable)
            {
                ImGuiInputTextCallbackData callback_data;
                callback_data.EventFlag = ImGuiInputTextFlags.CallbackResize;
                callback_data.Flags = flags;
                callback_data.Buf = buf;
                callback_data.BufTextLen = apply_new_text_length;
                callback_data.BufSize = ImMax(cast(int)buf.length, apply_new_text_length + 1);
                callback_data.UserData = callback_user_data;
                callback(&callback_data);
                buf = callback_data.Buf[0..callback_data.BufSize];
                apply_new_text_length = ImMin(callback_data.BufTextLen, cast(int)buf.length - 1);
                IM_ASSERT(apply_new_text_length <= buf.length);
            }
            //IMGUI_DEBUG_LOG("InputText(\"%s\"): apply_new_text length %d\n", label, apply_new_text_length);

            // If the underlying buffer resize was denied or not carried to the next frame, apply_new_text_length+1 may be >= buf.length.
            ImStrncpy(buf, apply_new_text);
            value_changed = true;
        }

        // Clear temporary user storage
        state.Flags = ImGuiInputTextFlags.None;
        state.UserCallback = NULL;
        state.UserCallbackData = NULL;
    }

    // Release active ID at the end of the function (so e.g. pressing Return still does a final application of the value)
    if (clear_active_id && g.ActiveId == id)
        ClearActiveID();

    // Render frame
    if (!is_multiline)
    {
        RenderNavHighlight(frame_bb, id);
        RenderFrame(frame_bb.Min, frame_bb.Max, GetColorU32(ImGuiCol.FrameBg), true, style.FrameRounding);
    }

    const ImVec4 clip_rect = ImVec4(frame_bb.Min.x, frame_bb.Min.y, frame_bb.Min.x + inner_size.x, frame_bb.Min.y + inner_size.y); // Not using frame_bb.Max because we have adjusted size
    ImVec2 draw_pos = is_multiline ? draw_window.DC.CursorPos : frame_bb.Min + style.FramePadding;
    ImVec2 text_size = ImVec2(0.0f, 0.0f);

    // Set upper limit of single-line InputTextEx() at 2 million characters strings. The current pathological worst case is a long line
    // without any carriage return, which would makes ImFont::RenderText() reserve too many vertices and probably crash. Avoid it altogether.
    // Note that we only use this limit on single-line InputText(), so a pathologically large line on a InputTextMultiline() would still crash.
    const int buf_display_max_length = 2 * 1024 * 1024;
    const (char)[] buf_display = (g.ActiveId == id && !is_readonly) ? state.TextA.asArray() : buf;
    size_t buf_display_end = 0; // We have specialized paths below for setting the length
    if (is_displaying_hint)
    {
        buf_display = hint;
        buf_display_end = hint.length;
    }

    // Render text. We currently only render selection when the widget is active or while scrolling.
    // FIXME: We could remove the '&& render_cursor' to keep rendering selection when inactive.
    if (render_cursor || render_selection)
    {
        IM_ASSERT(state != NULL);
        if (!is_displaying_hint)
            buf_display_end = state.CurLenA;

        // Render text (with cursor and selection)
        // This is going to be messy. We need to:
        // - Display the text (this alone can be more easily clipped)
        // - Handle scrolling, highlight selection, display cursor (those all requires some form of 1d->2d cursor position calculation)
        // - Measure text height (for scrollbar)
        // We are attempting to do most of that in **one main pass** to minimize the computation cost (non-negligible for large amount of text) + 2nd pass for selection rendering (we could merge them by an extra refactoring effort)
        // FIXME: This should occur on buf_display but we'd need to maintain cursor/select_start/select_end for UTF-8.
        const ImWchar* text_begin = state.TextW.Data;
        ImVec2 cursor_offset, select_start_offset;

        {
            // Find lines numbers straddling 'cursor' (slot 0) and 'select_start' (slot 1) positions.
            const (ImWchar)*[2] searches_input_ptr = [ NULL, NULL ];
            int[2] searches_result_line_no = [ -1000, -1000 ];
            int searches_remaining = 0;
            if (render_cursor)
            {
                searches_input_ptr[0] = text_begin + state.Stb.cursor;
                searches_result_line_no[0] = -1;
                searches_remaining++;
            }
            if (render_selection)
            {
                searches_input_ptr[1] = text_begin + ImMin(state.Stb.select_start, state.Stb.select_end);
                searches_result_line_no[1] = -1;
                searches_remaining++;
            }

            // Iterate all lines to find our line numbers
            // In multi-line mode, we never exit the loop until all lines are counted, so add one extra to the searches_remaining counter.
            searches_remaining += is_multiline ? 1 : 0;
            int line_count = 0;
            //for (const ImWchar* s = text_begin; (s = (const ImWchar*)wcschr((const wchar_t*)s, (wchar_t)'\n')) != NULL; s++)  // FIXME-OPT: Could use this when wchar_t are 16-bit
            for (const (ImWchar)* s = text_begin; *s != 0; s++)
                if (*s == '\n')
                {
                    line_count++;
                    if (searches_result_line_no[0] == -1 && s >= searches_input_ptr[0]) { searches_result_line_no[0] = line_count; if (--searches_remaining <= 0) break; }
                    if (searches_result_line_no[1] == -1 && s >= searches_input_ptr[1]) { searches_result_line_no[1] = line_count; if (--searches_remaining <= 0) break; }
                }
            line_count++;
            if (searches_result_line_no[0] == -1)
                searches_result_line_no[0] = line_count;
            if (searches_result_line_no[1] == -1)
                searches_result_line_no[1] = line_count;

            // Calculate 2d position by finding the beginning of the line and measuring distance
            cursor_offset.x = InputTextCalcTextSizeW(ImStrbolW(searches_input_ptr[0], text_begin), searches_input_ptr[0]).x;
            cursor_offset.y = searches_result_line_no[0] * g.FontSize;
            if (searches_result_line_no[1] >= 0)
            {
                select_start_offset.x = InputTextCalcTextSizeW(ImStrbolW(searches_input_ptr[1], text_begin), searches_input_ptr[1]).x;
                select_start_offset.y = searches_result_line_no[1] * g.FontSize;
            }

            // Store text height (note that we haven't calculated text width at all, see GitHub issues #383, #1224)
            if (is_multiline)
                text_size = ImVec2(inner_size.x, line_count * g.FontSize);
        }

        // Scroll
        if (render_cursor && state.CursorFollow)
        {
            // Horizontal scroll in chunks of quarter width
            if (!(flags & ImGuiInputTextFlags.NoHorizontalScroll))
            {
                const float scroll_increment_x = inner_size.x * 0.25f;
                const float visible_width = inner_size.x - style.FramePadding.x;
                if (cursor_offset.x < state.ScrollX)
                    state.ScrollX = IM_FLOOR(ImMax(0.0f, cursor_offset.x - scroll_increment_x));
                else if (cursor_offset.x - visible_width >= state.ScrollX)
                    state.ScrollX = IM_FLOOR(cursor_offset.x - visible_width + scroll_increment_x);
            }
            else
            {
                state.ScrollX = 0.0f;
            }

            // Vertical scroll
            if (is_multiline)
            {
                // Test if cursor is vertically visible
                if (cursor_offset.y - g.FontSize < scroll_y)
                    scroll_y = ImMax(0.0f, cursor_offset.y - g.FontSize);
                else if (cursor_offset.y - inner_size.y >= scroll_y)
                    scroll_y = cursor_offset.y - inner_size.y + style.FramePadding.y * 2.0f;
                const float scroll_max_y = ImMax((text_size.y + style.FramePadding.y * 2.0f) - inner_size.y, 0.0f);
                scroll_y = ImClamp(scroll_y, 0.0f, scroll_max_y);
                draw_pos.y += (draw_window.Scroll.y - scroll_y);   // Manipulate cursor pos immediately avoid a frame of lag
                draw_window.Scroll.y = scroll_y;
            }

            state.CursorFollow = false;
        }

        // Draw selection
        const ImVec2 draw_scroll = ImVec2(state.ScrollX, 0.0f);
        if (render_selection)
        {
            const ImWchar* text_selected_begin = text_begin + ImMin(state.Stb.select_start, state.Stb.select_end);
            const ImWchar* text_selected_end = text_begin + ImMax(state.Stb.select_start, state.Stb.select_end);

            ImU32 bg_color = GetColorU32(ImGuiCol.TextSelectedBg, render_cursor ? 1.0f : 0.6f); // FIXME: current code flow mandate that render_cursor is always true here, we are leaving the transparent one for tests.
            float bg_offy_up = is_multiline ? 0.0f : -1.0f;    // FIXME: those offsets should be part of the style? they don't play so well with multi-line selection.
            float bg_offy_dn = is_multiline ? 0.0f : 2.0f;
            ImVec2 rect_pos = draw_pos + select_start_offset - draw_scroll;
            for (const (ImWchar)* p = text_selected_begin; p < text_selected_end; )
            {
                if (rect_pos.y > clip_rect.w + g.FontSize)
                    break;
                if (rect_pos.y < clip_rect.y)
                {
                    //p = (const ImWchar*)wmemchr((const wchar_t*)p, '\n', text_selected_end - p);  // FIXME-OPT: Could use this when wchar_t are 16-bit
                    //p = p ? p + 1 : text_selected_end;
                    while (p < text_selected_end)
                        if (*p++ == '\n')
                            break;
                }
                else
                {
                    ImVec2 rect_size = InputTextCalcTextSizeW(p, text_selected_end, &p, NULL, true);
                    if (rect_size.x <= 0.0f) rect_size.x = IM_FLOOR(g.Font.GetCharAdvance(cast(ImWchar)' ') * 0.50f); // So we can see selected empty lines
                    ImRect rect = ImRect(rect_pos + ImVec2(0.0f, bg_offy_up - g.FontSize), rect_pos + ImVec2(rect_size.x, bg_offy_dn));
                    rect.ClipWith(ImRect(clip_rect));
                    if (rect.Overlaps(ImRect(clip_rect)))
                        draw_window.DrawList.AddRectFilled(rect.Min, rect.Max, bg_color);
                }
                rect_pos.x = draw_pos.x - draw_scroll.x;
                rect_pos.y += g.FontSize;
            }
        }

        // We test for 'buf_display_max_length' as a way to avoid some pathological cases (e.g. single-line 1 MB string) which would make ImDrawList crash.
        if (is_multiline || buf_display_end < buf_display_max_length)
        {
            ImU32 col = GetColorU32(is_displaying_hint ? ImGuiCol.TextDisabled : ImGuiCol.Text);
            draw_window.DrawList.AddText(g.Font, g.FontSize, draw_pos - draw_scroll, col, cast(string)buf_display[0..buf_display_end], 0.0f, is_multiline ? NULL : &clip_rect);
        }

        // Draw blinking cursor
        if (render_cursor)
        {
            state.CursorAnim += io.DeltaTime;
            bool cursor_is_visible = (!g.IO.ConfigInputTextCursorBlink) || (state.CursorAnim <= 0.0f) || ImFmod(state.CursorAnim, 1.20f) <= 0.80f;
            ImVec2 cursor_screen_pos = ImFloor(draw_pos + cursor_offset - draw_scroll);
            ImRect cursor_screen_rect = ImRect(cursor_screen_pos.x, cursor_screen_pos.y - g.FontSize + 0.5f, cursor_screen_pos.x + 1.0f, cursor_screen_pos.y-1.5f);
            if (cursor_is_visible && cursor_screen_rect.Overlaps(ImRect(clip_rect)))
                draw_window.DrawList.AddLine(cursor_screen_rect.Min, cursor_screen_rect.GetBL(), GetColorU32(ImGuiCol.Text));

            // Notify OS of text input position for advanced IME (-1 x offset so that Windows IME can cover our cursor. Bit of an extra nicety.)
            if (!is_readonly)
                g.PlatformImePos = ImVec2(cursor_screen_pos.x - 1.0f, cursor_screen_pos.y - g.FontSize);
        }
    }
    else
    {
        // Render text only (no selection, no cursor)
        if (is_multiline)
            text_size = ImVec2(inner_size.x, InputTextCalcTextLenAndLineCount(buf_display, &buf_display_end) * g.FontSize); // We don't need width
        else if (!is_displaying_hint && g.ActiveId == id)
            buf_display_end = state.CurLenA;
        else if (!is_displaying_hint)
            buf_display_end = strlen(buf_display);

        if (is_multiline || buf_display_end < buf_display_max_length)
        {
            ImU32 col = GetColorU32(is_displaying_hint ? ImGuiCol.TextDisabled : ImGuiCol.Text);
            draw_window.DrawList.AddText(g.Font, g.FontSize, draw_pos, col, cast(string)buf_display[0..buf_display_end], 0.0f, is_multiline ? NULL : &clip_rect);
        }
    }

    if (is_password && !is_displaying_hint)
        PopFont();

    if (is_multiline)
    {
        Dummy(ImVec2(text_size.x, text_size.y + style.FramePadding.y));
        EndChild();
        EndGroup();
    }

    // Log as text
    if (g.LogEnabled && (!is_password || is_displaying_hint))
    {
        LogSetNextTextDecoration("{", "}");
        LogRenderedText(&draw_pos, cast(string)buf_display[0..buf_display_end]);
    }

    if (label_size.x > 0)
        RenderText(ImVec2(frame_bb.Max.x + style.ItemInnerSpacing.x, frame_bb.Min.y + style.FramePadding.y), label);

    if (value_changed && !(flags & ImGuiInputTextFlags.NoMarkEdited))
        MarkItemEdited(id);

    IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags);
    if ((flags & ImGuiInputTextFlags.EnterReturnsTrue) != 0)
        return enter_pressed;
    else
        return value_changed;
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: ColorEdit, ColorPicker, ColorButton, etc.
//-------------------------------------------------------------------------
// - ColorEdit3()
// - ColorEdit4()
// - ColorPicker3()
// - RenderColorRectWithAlphaCheckerboard() [Internal]
// - ColorPicker4()
// - ColorButton()
// - SetColorEditOptions()
// - ColorTooltip() [Internal]
// - ColorEditOptionsPopup() [Internal]
// - ColorPickerOptionsPopup() [Internal]
//-------------------------------------------------------------------------

bool ColorEdit3(string label, float[/*3*/] col, ImGuiColorEditFlags flags = ImGuiColorEditFlags.None)
{
    return ColorEdit4(label, col, flags | ImGuiColorEditFlags.NoAlpha);
}

// Edit colors components (each component in 0.0f..1.0f range).
// See enum ImGuiColorEditFlags_ for available options. e.g. Only access 3 floats if ImGuiColorEditFlags_NoAlpha flag is set.
// With typical options: Left-click on color square to open color picker. Right-click to open option menu. CTRL-Click over input fields to edit them and TAB to go to next item.
bool ColorEdit4(string label, float[/*4*/] col, ImGuiColorEditFlags flags = ImGuiColorEditFlags.None)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    ImGuiContext* g = GImGui;
    const ImGuiStyle* style = &g.Style;
    const float square_sz = GetFrameHeight();
    const float w_full = CalcItemWidth();
    const float w_button = (flags & ImGuiColorEditFlags.NoSmallPreview) ? 0.0f : (square_sz + style.ItemInnerSpacing.x);
    const float w_inputs = w_full - w_button;
    string label_display_end = FindRenderedTextEnd(label);
    g.NextItemData.ClearFlags();

    BeginGroup();
    PushID(label);

    // If we're not showing any slider there's no point in doing any HSV conversions
    const ImGuiColorEditFlags flags_untouched = flags;
    if (flags & ImGuiColorEditFlags.NoInputs)
        flags = (flags & (~ImGuiColorEditFlags.DisplayMask_)) | ImGuiColorEditFlags.DisplayRGB | ImGuiColorEditFlags.NoOptions;

    // Context menu: display and modify options (before defaults are applied)
    if (!(flags & ImGuiColorEditFlags.NoOptions))
        ColorEditOptionsPopup(col.ptr, flags);

    // Read stored options
    if (!(flags & ImGuiColorEditFlags.DisplayMask_))
        flags |= (g.ColorEditOptions & ImGuiColorEditFlags.DisplayMask_);
    if (!(flags & ImGuiColorEditFlags.DataTypeMask_))
        flags |= (g.ColorEditOptions & ImGuiColorEditFlags.DataTypeMask_);
    if (!(flags & ImGuiColorEditFlags.PickerMask_))
        flags |= (g.ColorEditOptions & ImGuiColorEditFlags.PickerMask_);
    if (!(flags & ImGuiColorEditFlags.InputMask_))
        flags |= (g.ColorEditOptions & ImGuiColorEditFlags.InputMask_);
    flags |= (g.ColorEditOptions & ~(ImGuiColorEditFlags.DisplayMask_ | ImGuiColorEditFlags.DataTypeMask_ | ImGuiColorEditFlags.PickerMask_ | ImGuiColorEditFlags.InputMask_));
    IM_ASSERT(ImIsPowerOfTwo(flags & ImGuiColorEditFlags.DisplayMask_)); // Check that only 1 is selected
    IM_ASSERT(ImIsPowerOfTwo(flags & ImGuiColorEditFlags.InputMask_));   // Check that only 1 is selected

    const bool alpha = (flags & ImGuiColorEditFlags.NoAlpha) == 0;
    const bool hdr = (flags & ImGuiColorEditFlags.HDR) != 0;
    const int components = alpha ? 4 : 3;

    // Convert to the formats we need
    float[4] f = [ col[0], col[1], col[2], alpha ? col[3] : 1.0f ];
    if ((flags & ImGuiColorEditFlags.InputHSV) && (flags & ImGuiColorEditFlags.DisplayRGB))
        ColorConvertHSVtoRGB(f[0], f[1], f[2], f[0], f[1], f[2]);
    else if ((flags & ImGuiColorEditFlags.InputRGB) && (flags & ImGuiColorEditFlags.DisplayHSV))
    {
        // Hue is lost when converting from greyscale rgb (saturation=0). Restore it.
        ColorConvertRGBtoHSV(f[0], f[1], f[2], f[0], f[1], f[2]);
        if (memcmp(g.ColorEditLastColor, col, sizeof!(float) * 3) == 0)
        {
            if (f[1] == 0)
                f[0] = g.ColorEditLastHue;
            if (f[2] == 0)
                f[1] = g.ColorEditLastSat;
        }
    }
    int[4] i = [ IM_F32_TO_INT8_UNBOUND(f[0]), IM_F32_TO_INT8_UNBOUND(f[1]), IM_F32_TO_INT8_UNBOUND(f[2]), IM_F32_TO_INT8_UNBOUND(f[3]) ];

    bool value_changed = false;
    bool value_changed_as_float = false;

    const ImVec2 pos = window.DC.CursorPos;
    const float inputs_offset_x = (style.ColorButtonPosition == ImGuiDir.Left) ? w_button : 0.0f;
    window.DC.CursorPos.x = pos.x + inputs_offset_x;

    if ((flags & (ImGuiColorEditFlags.DisplayRGB | ImGuiColorEditFlags.DisplayHSV)) != 0 && (flags & ImGuiColorEditFlags.NoInputs) == 0)
    {
        // RGB/HSV 0..255 Sliders
        const float w_item_one  = ImMax(1.0f, IM_FLOOR((w_inputs - (style.ItemInnerSpacing.x) * (components - 1)) / cast(float)components));
        const float w_item_last = ImMax(1.0f, IM_FLOOR(w_inputs - (w_item_one + style.ItemInnerSpacing.x) * (components - 1)));

        const bool hide_prefix = (w_item_one <= CalcTextSize((flags & ImGuiColorEditFlags.Float) ? "M:0.000" : "M:000").x);
        __gshared string[4] ids = [ "##X", "##Y", "##Z", "##W" ];
        __gshared string[4][3] fmt_table_int =
        [
            [   "%3d",   "%3d",   "%3d",   "%3d" ], // Short display
            [ "R:%3d", "G:%3d", "B:%3d", "A:%3d" ], // Long display for RGBA
            [ "H:%3d", "S:%3d", "V:%3d", "A:%3d" ]  // Long display for HSVA
        ];
        __gshared string[4][3] fmt_table_float =
        [
            [   "%0.3f",   "%0.3f",   "%0.3f",   "%0.3f" ], // Short display
            [ "R:%0.3f", "G:%0.3f", "B:%0.3f", "A:%0.3f" ], // Long display for RGBA
            [ "H:%0.3f", "S:%0.3f", "V:%0.3f", "A:%0.3f" ]  // Long display for HSVA
        ];
        const int fmt_idx = hide_prefix ? 0 : (flags & ImGuiColorEditFlags.DisplayHSV) ? 2 : 1;

        for (int n = 0; n < components; n++)
        {
            if (n > 0)
                SameLine(0, style.ItemInnerSpacing.x);
            SetNextItemWidth((n + 1 < components) ? w_item_one : w_item_last);

            // FIXME: When ImGuiColorEditFlags_HDR flag is passed HS values snap in weird ways when SV values go below 0.
            if (flags & ImGuiColorEditFlags.Float)
            {
                value_changed |= DragFloat(ids[n], &f[n], 1.0f / 255.0f, 0.0f, hdr ? 0.0f : 1.0f, fmt_table_float[fmt_idx][n]);
                value_changed_as_float |= value_changed;
            }
            else
            {
                value_changed |= DragInt(ids[n], &i[n], 1.0f, 0, hdr ? 0 : 255, fmt_table_int[fmt_idx][n]);
            }
            if (!(flags & ImGuiColorEditFlags.NoOptions))
                OpenPopupOnItemClick("context");
        }
    }
    else if ((flags & ImGuiColorEditFlags.DisplayHex) != 0 && (flags & ImGuiColorEditFlags.NoInputs) == 0)
    {
        // RGB Hexadecimal Input
        char[64] buf;
        if (alpha)
            ImFormatString(buf, "#%02X%02X%02X%02X", ImClamp(i[0], 0, 255), ImClamp(i[1], 0, 255), ImClamp(i[2], 0, 255), ImClamp(i[3], 0, 255));
        else
            ImFormatString(buf, "#%02X%02X%02X", ImClamp(i[0], 0, 255), ImClamp(i[1], 0, 255), ImClamp(i[2], 0, 255));
        SetNextItemWidth(w_inputs);
        if (InputText("##Text", buf, ImGuiInputTextFlags.CharsHexadecimal | ImGuiInputTextFlags.CharsUppercase))
        {
            value_changed = true;
            size_t p = 0;
            while (p < buf.length && (buf[p] == '#' || ImCharIsBlankA(buf[p])))
                p++;
            i[0] = i[1] = i[2] = 0;
            i[3] = 0xFF; // alpha default to 255 is not parsed by scanf (e.g. inputting #FFFFFF omitting alpha)
            int r;
            if (alpha)
                r = sscanf(ImCstring(buf[p..$]), "%02X%02X%02X%02X", cast(uint*)&i[0], cast(uint*)&i[1], cast(uint*)&i[2], cast(uint*)&i[3]); // Treat at unsigned (%X is unsigned)
            else
                r = sscanf(ImCstring(buf[p..$]), "%02X%02X%02X", cast(uint*)&i[0], cast(uint*)&i[1], cast(uint*)&i[2]);
            IM_UNUSED(r); // Fixes C6031: Return value ignored: 'sscanf'.
        }
        if (!(flags & ImGuiColorEditFlags.NoOptions))
            OpenPopupOnItemClick("context");
    }

    ImGuiWindow* picker_active_window = NULL;
    if (!(flags & ImGuiColorEditFlags.NoSmallPreview))
    {
        const float button_offset_x = ((flags & ImGuiColorEditFlags.NoInputs) || (style.ColorButtonPosition == ImGuiDir.Left)) ? 0.0f : w_inputs + style.ItemInnerSpacing.x;
        window.DC.CursorPos = ImVec2(pos.x + button_offset_x, pos.y);

        const ImVec4 col_v4 = ImVec4(col[0], col[1], col[2], alpha ? col[3] : 1.0f);
        if (ColorButton("##ColorButton", col_v4, flags))
        {
            if (!(flags & ImGuiColorEditFlags.NoPicker))
            {
                // Store current color and open a picker
                g.ColorPickerRef = col_v4;
                OpenPopup("picker");
                SetNextWindowPos(g.LastItemData.Rect.GetBL() + ImVec2(-1, style.ItemSpacing.y));
            }
        }
        if (!(flags & ImGuiColorEditFlags.NoOptions))
            OpenPopupOnItemClick("context");

        if (BeginPopup("picker"))
        {
            picker_active_window = g.CurrentWindow;
            if (label_display_end.length != 0)
            {
                TextEx(label_display_end);
                Spacing();
            }
            ImGuiColorEditFlags picker_flags_to_forward = ImGuiColorEditFlags.DataTypeMask_ | ImGuiColorEditFlags.PickerMask_ | ImGuiColorEditFlags.InputMask_ | ImGuiColorEditFlags.HDR | ImGuiColorEditFlags.NoAlpha | ImGuiColorEditFlags.AlphaBar;
            ImGuiColorEditFlags picker_flags = (flags_untouched & picker_flags_to_forward) | ImGuiColorEditFlags.DisplayMask_ | ImGuiColorEditFlags.NoLabel | ImGuiColorEditFlags.AlphaPreviewHalf;
            SetNextItemWidth(square_sz * 12.0f); // Use 256 + bar sizes?
            value_changed |= ColorPicker4("##picker", col, picker_flags, g.ColorPickerRef.array().ptr);
            EndPopup();
        }
    }

    if (label_display_end.length != 0 && !(flags & ImGuiColorEditFlags.NoLabel))
    {
        const float text_offset_x = (flags & ImGuiColorEditFlags.NoInputs) ? w_button : w_full + style.ItemInnerSpacing.x;
        window.DC.CursorPos = ImVec2(pos.x + text_offset_x, pos.y + style.FramePadding.y);
        TextEx(label_display_end);
    }

    // Convert back
    if (value_changed && picker_active_window == NULL)
    {
        if (!value_changed_as_float)
            for (int n = 0; n < 4; n++)
                f[n] = i[n] / 255.0f;
        if ((flags & ImGuiColorEditFlags.DisplayHSV) && (flags & ImGuiColorEditFlags.InputRGB))
        {
            g.ColorEditLastHue = f[0];
            g.ColorEditLastSat = f[1];
            ColorConvertHSVtoRGB(f[0], f[1], f[2], f[0], f[1], f[2]);
            memcpy(g.ColorEditLastColor, f, sizeof!(float) * 3);
        }
        if ((flags & ImGuiColorEditFlags.DisplayRGB) && (flags & ImGuiColorEditFlags.InputHSV))
            ColorConvertRGBtoHSV(f[0], f[1], f[2], f[0], f[1], f[2]);

        col[0] = f[0];
        col[1] = f[1];
        col[2] = f[2];
        if (alpha)
            col[3] = f[3];
    }

    PopID();
    EndGroup();

    // Drag and Drop Target
    // NB: The flag test is merely an optional micro-optimization, BeginDragDropTarget() does the same test.
    if ((g.LastItemData.StatusFlags & ImGuiItemStatusFlags.HoveredRect) && !(flags & ImGuiColorEditFlags.NoDragDrop) && BeginDragDropTarget())
    {
        bool accepted_drag_drop = false;
        const (ImGuiPayload)* payload = AcceptDragDropPayload(IMGUI_PAYLOAD_TYPE_COLOR_3F);
        if (payload)
        {
            memcpy(col, payload.Data, sizeof!(float) * 3); // Preserve alpha if any //-V512
            value_changed = accepted_drag_drop = true;
        }
        payload = AcceptDragDropPayload(IMGUI_PAYLOAD_TYPE_COLOR_4F);
        if (payload)
        {
            memcpy(col, payload.Data, sizeof!(float) * components);
            value_changed = accepted_drag_drop = true;
        }

        // Drag-drop payloads are always RGB
        if (accepted_drag_drop && (flags & ImGuiColorEditFlags.InputHSV))
            ColorConvertRGBtoHSV(col[0], col[1], col[2], col[0], col[1], col[2]);
        EndDragDropTarget();
    }

    // When picker is being actively used, use its active id so IsItemActive() will function on ColorEdit4().
    if (picker_active_window && g.ActiveId != 0 && g.ActiveIdWindow == picker_active_window)
        g.LastItemData.ID = g.ActiveId;

    if (value_changed)
        MarkItemEdited(g.LastItemData.ID);

    return value_changed;
}

bool ColorEdit4(string label, ImVec4* col, ImGuiColorEditFlags flags = ImGuiColorEditFlags.None)
{
    return ColorEdit4(label, (&col.x)[0..4], flags);
}

bool ColorEdit3(string label, ImVec4* col, ImGuiColorEditFlags flags = ImGuiColorEditFlags.None)
{
    return ColorEdit4(label, (&col.x)[0..3], flags | ImGuiColorEditFlags.NoAlpha);
}

bool ColorPicker3(string label, float[/*3*/] col, ImGuiColorEditFlags flags = ImGuiColorEditFlags.None)
{
    float[4] col4 = [ col[0], col[1], col[2], 1.0f ];
    if (!ColorPicker4(label, col4, flags | ImGuiColorEditFlags.NoAlpha))
        return false;
    col[0] = col4[0]; col[1] = col4[1]; col[2] = col4[2];
    return true;
}

// Helper for ColorPicker4()
static void RenderArrowsForVerticalBar(ImDrawList* draw_list, ImVec2 pos, ImVec2 half_sz, float bar_w, float alpha)
{
    ubyte alpha8 = IM_F32_TO_INT8_SAT(alpha);
    RenderArrowPointingAt(draw_list, ImVec2(pos.x + half_sz.x + 1,         pos.y), ImVec2(half_sz.x + 2, half_sz.y + 1), ImGuiDir.Right, IM_COL32(0,0,0,alpha8));
    RenderArrowPointingAt(draw_list, ImVec2(pos.x + half_sz.x,             pos.y), half_sz,                              ImGuiDir.Right, IM_COL32(255,255,255,alpha8));
    RenderArrowPointingAt(draw_list, ImVec2(pos.x + bar_w - half_sz.x - 1, pos.y), ImVec2(half_sz.x + 2, half_sz.y + 1), ImGuiDir.Left,  IM_COL32(0,0,0,alpha8));
    RenderArrowPointingAt(draw_list, ImVec2(pos.x + bar_w - half_sz.x,     pos.y), half_sz,                              ImGuiDir.Left,  IM_COL32(255,255,255,alpha8));
}

// Note: ColorPicker4() only accesses 3 floats if ImGuiColorEditFlags_NoAlpha flag is set.
// (In C++ the 'float col[4]' notation for a function argument is equivalent to 'float* col', we only specify a size to facilitate understanding of the code.)
// FIXME: we adjust the big color square height based on item width, which may cause a flickering feedback loop (if automatic height makes a vertical scrollbar appears, affecting automatic width..)
// FIXME: this is trying to be aware of style.Alpha but not fully correct. Also, the color wheel will have overlapping glitches with (style.Alpha < 1.0)
bool ColorPicker4(string label, float[/*4*/] col, ImGuiColorEditFlags flags = ImGuiColorEditFlags.None, const float* ref_col = NULL)
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    ImDrawList* draw_list = window.DrawList;
    ImGuiStyle* style = &g.Style;
    ImGuiIO* io = &g.IO;

    const float width = CalcItemWidth();
    g.NextItemData.ClearFlags();

    PushID(label);
    BeginGroup();

    if (!(flags & ImGuiColorEditFlags.NoSidePreview))
        flags |= ImGuiColorEditFlags.NoSmallPreview;

    // Context menu: display and store options.
    if (!(flags & ImGuiColorEditFlags.NoOptions))
        ColorPickerOptionsPopup(col.ptr, flags);

    // Read stored options
    if (!(flags & ImGuiColorEditFlags.PickerMask_))
        flags |= ((g.ColorEditOptions & ImGuiColorEditFlags.PickerMask_) ? g.ColorEditOptions : ImGuiColorEditFlags.DefaultOptions_) & ImGuiColorEditFlags.PickerMask_;
    if (!(flags & ImGuiColorEditFlags.InputMask_))
        flags |= ((g.ColorEditOptions & ImGuiColorEditFlags.InputMask_) ? g.ColorEditOptions : ImGuiColorEditFlags.DefaultOptions_) & ImGuiColorEditFlags.InputMask_;
    IM_ASSERT(ImIsPowerOfTwo(flags & ImGuiColorEditFlags.PickerMask_)); // Check that only 1 is selected
    IM_ASSERT(ImIsPowerOfTwo(flags & ImGuiColorEditFlags.InputMask_));  // Check that only 1 is selected
    if (!(flags & ImGuiColorEditFlags.NoOptions))
        flags |= (g.ColorEditOptions & ImGuiColorEditFlags.AlphaBar);

    // Setup
    int components = (flags & ImGuiColorEditFlags.NoAlpha) ? 3 : 4;
    bool alpha_bar = (flags & ImGuiColorEditFlags.AlphaBar) && !(flags & ImGuiColorEditFlags.NoAlpha);
    ImVec2 picker_pos = window.DC.CursorPos;
    float square_sz = GetFrameHeight();
    float bars_width = square_sz; // Arbitrary smallish width of Hue/Alpha picking bars
    float sv_picker_size = ImMax(bars_width * 1, width - (alpha_bar ? 2 : 1) * (bars_width + style.ItemInnerSpacing.x)); // Saturation/Value picking box
    float bar0_pos_x = picker_pos.x + sv_picker_size + style.ItemInnerSpacing.x;
    float bar1_pos_x = bar0_pos_x + bars_width + style.ItemInnerSpacing.x;
    float bars_triangles_half_sz = IM_FLOOR(bars_width * 0.20f);

    float[4] backup_initial_col;
    memcpy(backup_initial_col, col, components * sizeof!(float));

    float wheel_thickness = sv_picker_size * 0.08f;
    float wheel_r_outer = sv_picker_size * 0.50f;
    float wheel_r_inner = wheel_r_outer - wheel_thickness;
    ImVec2 wheel_center = ImVec2(picker_pos.x + (sv_picker_size + bars_width)*0.5f, picker_pos.y + sv_picker_size * 0.5f);

    // Note: the triangle is displayed rotated with triangle_pa pointing to Hue, but most coordinates stays unrotated for logic.
    float triangle_r = wheel_r_inner - cast(int)(sv_picker_size * 0.027f);
    ImVec2 triangle_pa = ImVec2(triangle_r, 0.0f); // Hue point.
    ImVec2 triangle_pb = ImVec2(triangle_r * -0.5f, triangle_r * -0.866025f); // Black point.
    ImVec2 triangle_pc = ImVec2(triangle_r * -0.5f, triangle_r * +0.866025f); // White point.

    float H = col[0], S = col[1], V = col[2];
    float R = col[0], G = col[1], B = col[2];
    if (flags & ImGuiColorEditFlags.InputRGB)
    {
        // Hue is lost when converting from greyscale rgb (saturation=0). Restore it.
        ColorConvertRGBtoHSV(R, G, B, H, S, V);
        if (memcmp(g.ColorEditLastColor, col, sizeof!(float) * 3) == 0)
        {
            if (S == 0)
                H = g.ColorEditLastHue;
            if (V == 0)
                S = g.ColorEditLastSat;
        }
    }
    else if (flags & ImGuiColorEditFlags.InputHSV)
    {
        ColorConvertHSVtoRGB(H, S, V, R, G, B);
    }

    bool value_changed = false, value_changed_h = false, value_changed_sv = false;

    PushItemFlag(ImGuiItemFlags.NoNav, true);
    if (flags & ImGuiColorEditFlags.PickerHueWheel)
    {
        // Hue wheel + SV triangle logic
        InvisibleButton("hsv", ImVec2(sv_picker_size + style.ItemInnerSpacing.x + bars_width, sv_picker_size));
        if (IsItemActive())
        {
            ImVec2 initial_off = g.IO.MouseClickedPos[0] - wheel_center;
            ImVec2 current_off = g.IO.MousePos - wheel_center;
            float initial_dist2 = ImLengthSqr(initial_off);
            if (initial_dist2 >= (wheel_r_inner - 1) * (wheel_r_inner - 1) && initial_dist2 <= (wheel_r_outer + 1) * (wheel_r_outer + 1))
            {
                // Interactive with Hue wheel
                H = ImAtan2(current_off.y, current_off.x) / IM_PI * 0.5f;
                if (H < 0.0f)
                    H += 1.0f;
                value_changed = value_changed_h = true;
            }
            float cos_hue_angle = ImCos(-H * 2.0f * IM_PI);
            float sin_hue_angle = ImSin(-H * 2.0f * IM_PI);
            if (ImTriangleContainsPoint(triangle_pa, triangle_pb, triangle_pc, ImRotate(initial_off, cos_hue_angle, sin_hue_angle)))
            {
                // Interacting with SV triangle
                ImVec2 current_off_unrotated = ImRotate(current_off, cos_hue_angle, sin_hue_angle);
                if (!ImTriangleContainsPoint(triangle_pa, triangle_pb, triangle_pc, current_off_unrotated))
                    current_off_unrotated = ImTriangleClosestPoint(triangle_pa, triangle_pb, triangle_pc, current_off_unrotated);
                float uu, vv, ww;
                ImTriangleBarycentricCoords(triangle_pa, triangle_pb, triangle_pc, current_off_unrotated, uu, vv, ww);
                V = ImClamp(1.0f - vv, 0.0001f, 1.0f);
                S = ImClamp(uu / V, 0.0001f, 1.0f);
                value_changed = value_changed_sv = true;
            }
        }
        if (!(flags & ImGuiColorEditFlags.NoOptions))
            OpenPopupOnItemClick("context");
    }
    else if (flags & ImGuiColorEditFlags.PickerHueBar)
    {
        // SV rectangle logic
        InvisibleButton("sv", ImVec2(sv_picker_size, sv_picker_size));
        if (IsItemActive())
        {
            S = ImSaturate((io.MousePos.x - picker_pos.x) / (sv_picker_size - 1));
            V = 1.0f - ImSaturate((io.MousePos.y - picker_pos.y) / (sv_picker_size - 1));
            value_changed = value_changed_sv = true;
        }
        if (!(flags & ImGuiColorEditFlags.NoOptions))
            OpenPopupOnItemClick("context");

        // Hue bar logic
        SetCursorScreenPos(ImVec2(bar0_pos_x, picker_pos.y));
        InvisibleButton("hue", ImVec2(bars_width, sv_picker_size));
        if (IsItemActive())
        {
            H = ImSaturate((io.MousePos.y - picker_pos.y) / (sv_picker_size - 1));
            value_changed = value_changed_h = true;
        }
    }

    // Alpha bar logic
    if (alpha_bar)
    {
        SetCursorScreenPos(ImVec2(bar1_pos_x, picker_pos.y));
        InvisibleButton("alpha", ImVec2(bars_width, sv_picker_size));
        if (IsItemActive())
        {
            col[3] = 1.0f - ImSaturate((io.MousePos.y - picker_pos.y) / (sv_picker_size - 1));
            value_changed = true;
        }
    }
    PopItemFlag(); // ImGuiItemFlags_NoNav

    if (!(flags & ImGuiColorEditFlags.NoSidePreview))
    {
        SameLine(0, style.ItemInnerSpacing.x);
        BeginGroup();
    }

    if (!(flags & ImGuiColorEditFlags.NoLabel))
    {
        string label_display_end = FindRenderedTextEnd(label);
        if (label_display_end.length != 0)
        {
            if (flags & ImGuiColorEditFlags.NoSidePreview)
                SameLine(0, style.ItemInnerSpacing.x);
            TextEx(label_display_end);
        }
    }

    if (!(flags & ImGuiColorEditFlags.NoSidePreview))
    {
        PushItemFlag(ImGuiItemFlags.NoNavDefaultFocus, true);
        ImVec4 col_v4 = ImVec4(col[0], col[1], col[2], (flags & ImGuiColorEditFlags.NoAlpha) ? 1.0f : col[3]);
        if (flags & ImGuiColorEditFlags.NoLabel)
            Text("Current");

        ImGuiColorEditFlags sub_flags_to_forward = ImGuiColorEditFlags.InputMask_ | ImGuiColorEditFlags.HDR | ImGuiColorEditFlags.AlphaPreview | ImGuiColorEditFlags.AlphaPreviewHalf | ImGuiColorEditFlags.NoTooltip;
        ColorButton("##current", col_v4, (flags & sub_flags_to_forward), ImVec2(square_sz * 3, square_sz * 2));
        if (ref_col != NULL)
        {
            Text("Original");
            ImVec4 ref_col_v4 = ImVec4(ref_col[0], ref_col[1], ref_col[2], (flags & ImGuiColorEditFlags.NoAlpha) ? 1.0f : ref_col[3]);
            if (ColorButton("##original", ref_col_v4, (flags & sub_flags_to_forward), ImVec2(square_sz * 3, square_sz * 2)))
            {
                memcpy(col, ref_col, components * sizeof!(float));
                value_changed = true;
            }
        }
        PopItemFlag();
        EndGroup();
    }

    // Convert back color to RGB
    if (value_changed_h || value_changed_sv)
    {
        if (flags & ImGuiColorEditFlags.InputRGB)
        {
            ColorConvertHSVtoRGB(H >= 1.0f ? H - 10 * 1e-6f : H, S > 0.0f ? S : 10 * 1e-6f, V > 0.0f ? V : 1e-6f, col[0], col[1], col[2]);
            g.ColorEditLastHue = H;
            g.ColorEditLastSat = S;
            memcpy(g.ColorEditLastColor, col, sizeof!(float) * 3);
        }
        else if (flags & ImGuiColorEditFlags.InputHSV)
        {
            col[0] = H;
            col[1] = S;
            col[2] = V;
        }
    }

    // R,G,B and H,S,V slider color editor
    bool value_changed_fix_hue_wrap = false;
    if ((flags & ImGuiColorEditFlags.NoInputs) == 0)
    {
        PushItemWidth((alpha_bar ? bar1_pos_x : bar0_pos_x) + bars_width - picker_pos.x);
        ImGuiColorEditFlags sub_flags_to_forward = ImGuiColorEditFlags.DataTypeMask_ | ImGuiColorEditFlags.InputMask_ | ImGuiColorEditFlags.HDR | ImGuiColorEditFlags.NoAlpha | ImGuiColorEditFlags.NoOptions | ImGuiColorEditFlags.NoSmallPreview | ImGuiColorEditFlags.AlphaPreview | ImGuiColorEditFlags.AlphaPreviewHalf;
        ImGuiColorEditFlags sub_flags = (flags & sub_flags_to_forward) | ImGuiColorEditFlags.NoPicker;
        if (flags & ImGuiColorEditFlags.DisplayRGB || (flags & ImGuiColorEditFlags.DisplayMask_) == 0)
            if (ColorEdit4("##rgb", col, sub_flags | ImGuiColorEditFlags.DisplayRGB))
            {
                // FIXME: Hackily differentiating using the DragInt (ActiveId != 0 && !ActiveIdAllowOverlap) vs. using the InputText or DropTarget.
                // For the later we don't want to run the hue-wrap canceling code. If you are well versed in HSV picker please provide your input! (See #2050)
                value_changed_fix_hue_wrap = (g.ActiveId != 0 && !g.ActiveIdAllowOverlap);
                value_changed = true;
            }
        if (flags & ImGuiColorEditFlags.DisplayHSV || (flags & ImGuiColorEditFlags.DisplayMask_) == 0)
            value_changed |= ColorEdit4("##hsv", col, sub_flags | ImGuiColorEditFlags.DisplayHSV);
        if (flags & ImGuiColorEditFlags.DisplayHex || (flags & ImGuiColorEditFlags.DisplayMask_) == 0)
            value_changed |= ColorEdit4("##hex", col, sub_flags | ImGuiColorEditFlags.DisplayHex);
        PopItemWidth();
    }

    // Try to cancel hue wrap (after ColorEdit4 call), if any
    if (value_changed_fix_hue_wrap && (flags & ImGuiColorEditFlags.InputRGB))
    {
        float new_H, new_S, new_V;
        ColorConvertRGBtoHSV(col[0], col[1], col[2], new_H, new_S, new_V);
        if (new_H <= 0 && H > 0)
        {
            if (new_V <= 0 && V != new_V)
                ColorConvertHSVtoRGB(H, S, new_V <= 0 ? V * 0.5f : new_V, col[0], col[1], col[2]);
            else if (new_S <= 0)
                ColorConvertHSVtoRGB(H, new_S <= 0 ? S * 0.5f : new_S, new_V, col[0], col[1], col[2]);
        }
    }

    if (value_changed)
    {
        if (flags & ImGuiColorEditFlags.InputRGB)
        {
            R = col[0];
            G = col[1];
            B = col[2];
            ColorConvertRGBtoHSV(R, G, B, H, S, V);
            if (memcmp(g.ColorEditLastColor, col, sizeof!(float) * 3) == 0) // Fix local Hue as display below will use it immediately.
            {
                if (S == 0)
                    H = g.ColorEditLastHue;
                if (V == 0)
                    S = g.ColorEditLastSat;
            }
        }
        else if (flags & ImGuiColorEditFlags.InputHSV)
        {
            H = col[0];
            S = col[1];
            V = col[2];
            ColorConvertHSVtoRGB(H, S, V, R, G, B);
        }
    }

    const ubyte style_alpha8 = IM_F32_TO_INT8_SAT(style.Alpha);
    const ImU32 col_black = IM_COL32(0,0,0,style_alpha8);
    const ImU32 col_white = IM_COL32(255,255,255,style_alpha8);
    const ImU32 col_midgrey = IM_COL32(128,128,128,style_alpha8);
    const ImU32[6 + 1] col_hues = [ IM_COL32(255,0,0,style_alpha8), IM_COL32(255,255,0,style_alpha8), IM_COL32(0,255,0,style_alpha8), IM_COL32(0,255,255,style_alpha8), IM_COL32(0,0,255,style_alpha8), IM_COL32(255,0,255,style_alpha8), IM_COL32(255,0,0,style_alpha8) ];

    ImVec4 hue_color_f = ImVec4(1, 1, 1, style.Alpha); ColorConvertHSVtoRGB(H, 1, 1, hue_color_f.x, hue_color_f.y, hue_color_f.z);
    ImU32 hue_color32 = ColorConvertFloat4ToU32(hue_color_f);
    ImU32 user_col32_striped_of_alpha = ColorConvertFloat4ToU32(ImVec4(R, G, B, style.Alpha)); // Important: this is still including the main rendering/style alpha!!

    ImVec2 sv_cursor_pos;

    if (flags & ImGuiColorEditFlags.PickerHueWheel)
    {
        // Render Hue Wheel
        const float aeps = 0.5f / wheel_r_outer; // Half a pixel arc length in radians (2pi cancels out).
        const int segment_per_arc = ImMax(4, cast(int)wheel_r_outer / 12);
        for (int n = 0; n < 6; n++)
        {
            const float a0 = (n)     /6.0f * 2.0f * IM_PI - aeps;
            const float a1 = (n+1.0f)/6.0f * 2.0f * IM_PI + aeps;
            const int vert_start_idx = draw_list.VtxBuffer.Size;
            draw_list.PathArcTo(wheel_center, (wheel_r_inner + wheel_r_outer)*0.5f, a0, a1, segment_per_arc);
            draw_list.PathStroke(col_white, ImDrawFlags.None, wheel_thickness);
            const int vert_end_idx = draw_list.VtxBuffer.Size;

            // Paint colors over existing vertices
            ImVec2 gradient_p0 = ImVec2(wheel_center.x + ImCos(a0) * wheel_r_inner, wheel_center.y + ImSin(a0) * wheel_r_inner);
            ImVec2 gradient_p1 = ImVec2(wheel_center.x + ImCos(a1) * wheel_r_inner, wheel_center.y + ImSin(a1) * wheel_r_inner);
            ShadeVertsLinearColorGradientKeepAlpha(draw_list, vert_start_idx, vert_end_idx, gradient_p0, gradient_p1, col_hues[n], col_hues[n + 1]);
        }

        // Render Cursor + preview on Hue Wheel
        float cos_hue_angle = ImCos(H * 2.0f * IM_PI);
        float sin_hue_angle = ImSin(H * 2.0f * IM_PI);
        ImVec2 hue_cursor_pos = ImVec2(wheel_center.x + cos_hue_angle * (wheel_r_inner + wheel_r_outer) * 0.5f, wheel_center.y + sin_hue_angle * (wheel_r_inner + wheel_r_outer) * 0.5f);
        float hue_cursor_rad = value_changed_h ? wheel_thickness * 0.65f : wheel_thickness * 0.55f;
        int hue_cursor_segments = ImClamp(cast(int)(hue_cursor_rad / 1.4f), 9, 32);
        draw_list.AddCircleFilled(hue_cursor_pos, hue_cursor_rad, hue_color32, hue_cursor_segments);
        draw_list.AddCircle(hue_cursor_pos, hue_cursor_rad + 1, col_midgrey, hue_cursor_segments);
        draw_list.AddCircle(hue_cursor_pos, hue_cursor_rad, col_white, hue_cursor_segments);

        // Render SV triangle (rotated according to hue)
        ImVec2 tra = wheel_center + ImRotate(triangle_pa, cos_hue_angle, sin_hue_angle);
        ImVec2 trb = wheel_center + ImRotate(triangle_pb, cos_hue_angle, sin_hue_angle);
        ImVec2 trc = wheel_center + ImRotate(triangle_pc, cos_hue_angle, sin_hue_angle);
        ImVec2 uv_white = GetFontTexUvWhitePixel();
        draw_list.PrimReserve(6, 6);
        draw_list.PrimVtx(tra, uv_white, hue_color32);
        draw_list.PrimVtx(trb, uv_white, hue_color32);
        draw_list.PrimVtx(trc, uv_white, col_white);
        draw_list.PrimVtx(tra, uv_white, 0);
        draw_list.PrimVtx(trb, uv_white, col_black);
        draw_list.PrimVtx(trc, uv_white, 0);
        draw_list.AddTriangle(tra, trb, trc, col_midgrey, 1.5f);
        sv_cursor_pos = ImLerp(ImLerp(trc, tra, ImSaturate(S)), trb, ImSaturate(1 - V));
    }
    else if (flags & ImGuiColorEditFlags.PickerHueBar)
    {
        // Render SV Square
        draw_list.AddRectFilledMultiColor(picker_pos, picker_pos + ImVec2(sv_picker_size, sv_picker_size), col_white, hue_color32, hue_color32, col_white);
        draw_list.AddRectFilledMultiColor(picker_pos, picker_pos + ImVec2(sv_picker_size, sv_picker_size), 0, 0, col_black, col_black);
        RenderFrameBorder(picker_pos, picker_pos + ImVec2(sv_picker_size, sv_picker_size), 0.0f);
        sv_cursor_pos.x = ImClamp(IM_ROUND(picker_pos.x + ImSaturate(S)     * sv_picker_size), picker_pos.x + 2, picker_pos.x + sv_picker_size - 2); // Sneakily prevent the circle to stick out too much
        sv_cursor_pos.y = ImClamp(IM_ROUND(picker_pos.y + ImSaturate(1 - V) * sv_picker_size), picker_pos.y + 2, picker_pos.y + sv_picker_size - 2);

        // Render Hue Bar
        for (int i = 0; i < 6; ++i)
            draw_list.AddRectFilledMultiColor(ImVec2(bar0_pos_x, picker_pos.y + i * (sv_picker_size / 6)), ImVec2(bar0_pos_x + bars_width, picker_pos.y + (i + 1) * (sv_picker_size / 6)), col_hues[i], col_hues[i], col_hues[i + 1], col_hues[i + 1]);
        float bar0_line_y = IM_ROUND(picker_pos.y + H * sv_picker_size);
        RenderFrameBorder(ImVec2(bar0_pos_x, picker_pos.y), ImVec2(bar0_pos_x + bars_width, picker_pos.y + sv_picker_size), 0.0f);
        RenderArrowsForVerticalBar(draw_list, ImVec2(bar0_pos_x - 1, bar0_line_y), ImVec2(bars_triangles_half_sz + 1, bars_triangles_half_sz), bars_width + 2.0f, style.Alpha);
    }

    // Render cursor/preview circle (clamp S/V within 0..1 range because floating points colors may lead HSV values to be out of range)
    float sv_cursor_rad = value_changed_sv ? 10.0f : 6.0f;
    draw_list.AddCircleFilled(sv_cursor_pos, sv_cursor_rad, user_col32_striped_of_alpha, 12);
    draw_list.AddCircle(sv_cursor_pos, sv_cursor_rad + 1, col_midgrey, 12);
    draw_list.AddCircle(sv_cursor_pos, sv_cursor_rad, col_white, 12);

    // Render alpha bar
    if (alpha_bar)
    {
        float alpha = ImSaturate(col[3]);
        ImRect bar1_bb = ImRect(bar1_pos_x, picker_pos.y, bar1_pos_x + bars_width, picker_pos.y + sv_picker_size);
        RenderColorRectWithAlphaCheckerboard(draw_list, bar1_bb.Min, bar1_bb.Max, 0, bar1_bb.GetWidth() / 2.0f, ImVec2(0.0f, 0.0f));
        draw_list.AddRectFilledMultiColor(bar1_bb.Min, bar1_bb.Max, user_col32_striped_of_alpha, user_col32_striped_of_alpha, user_col32_striped_of_alpha & ~IM_COL32_A_MASK, user_col32_striped_of_alpha & ~IM_COL32_A_MASK);
        float bar1_line_y = IM_ROUND(picker_pos.y + (1.0f - alpha) * sv_picker_size);
        RenderFrameBorder(bar1_bb.Min, bar1_bb.Max, 0.0f);
        RenderArrowsForVerticalBar(draw_list, ImVec2(bar1_pos_x - 1, bar1_line_y), ImVec2(bars_triangles_half_sz + 1, bars_triangles_half_sz), bars_width + 2.0f, style.Alpha);
    }

    EndGroup();

    if (value_changed && memcmp(backup_initial_col, col, components * sizeof!(float)) == 0)
        value_changed = false;
    if (value_changed)
        MarkItemEdited(g.LastItemData.ID);

    PopID();

    return value_changed;
}

bool ColorPicker4(string label, ImVec4* col, ImGuiColorEditFlags flags = ImGuiColorEditFlags.None, const float* ref_col = NULL)
{
    return ColorPicker4(label, (&col.x)[0..4], flags, ref_col);
}

// A little color square. Return true when clicked.
// FIXME: May want to display/ignore the alpha component in the color display? Yet show it in the tooltip.
// 'desc_id' is not called 'label' because we don't display it next to the button, but only in the tooltip.
// Note that 'col' may be encoded in HSV if ImGuiColorEditFlags_InputHSV is set.
bool ColorButton(string desc_id, const ImVec4/*&*/ col, ImGuiColorEditFlags flags = ImGuiColorEditFlags.None, ImVec2 size = ImVec2(0, 0))
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    ImGuiContext* g = GImGui;
    const ImGuiID id = window.GetID(desc_id);
    float default_size = GetFrameHeight();
    if (size.x == 0.0f)
        size.x = default_size;
    if (size.y == 0.0f)
        size.y = default_size;
    const ImRect bb = ImRect(window.DC.CursorPos, window.DC.CursorPos + size);
    ItemSize(bb, (size.y >= default_size) ? g.Style.FramePadding.y : 0.0f);
    if (!ItemAdd(bb, id))
        return false;

    bool hovered, held;
    bool pressed = ButtonBehavior(bb, id, &hovered, &held);

    if (flags & ImGuiColorEditFlags.NoAlpha)
        flags &= ~(ImGuiColorEditFlags.AlphaPreview | ImGuiColorEditFlags.AlphaPreviewHalf);

    ImVec4 col_rgb = col;
    if (flags & ImGuiColorEditFlags.InputHSV)
        ColorConvertHSVtoRGB(col_rgb.x, col_rgb.y, col_rgb.z, col_rgb.x, col_rgb.y, col_rgb.z);

    ImVec4 col_rgb_without_alpha = ImVec4(col_rgb.x, col_rgb.y, col_rgb.z, 1.0f);
    float grid_step = ImMin(size.x, size.y) / 2.99f;
    float rounding = ImMin(g.Style.FrameRounding, grid_step * 0.5f);
    ImRect bb_inner = bb;
    float off = 0.0f;
    if ((flags & ImGuiColorEditFlags.NoBorder) == 0)
    {
        off = -0.75f; // The border (using Col_FrameBg) tends to look off when color is near-opaque and rounding is enabled. This offset seemed like a good middle ground to reduce those artifacts.
        bb_inner.Expand(off);
    }
    if ((flags & ImGuiColorEditFlags.AlphaPreviewHalf) && col_rgb.w < 1.0f)
    {
        float mid_x = IM_ROUND((bb_inner.Min.x + bb_inner.Max.x) * 0.5f);
        RenderColorRectWithAlphaCheckerboard(window.DrawList, ImVec2(bb_inner.Min.x + grid_step, bb_inner.Min.y), bb_inner.Max, GetColorU32(col_rgb), grid_step, ImVec2(-grid_step + off, off), rounding, ImDrawFlags.RoundCornersRight);
        window.DrawList.AddRectFilled(bb_inner.Min, ImVec2(mid_x, bb_inner.Max.y), GetColorU32(col_rgb_without_alpha), rounding, ImDrawFlags.RoundCornersLeft);
    }
    else
    {
        // Because GetColorU32() multiplies by the global style Alpha and we don't want to display a checkerboard if the source code had no alpha
        ImVec4 col_source = (flags & ImGuiColorEditFlags.AlphaPreview) ? col_rgb : col_rgb_without_alpha;
        if (col_source.w < 1.0f)
            RenderColorRectWithAlphaCheckerboard(window.DrawList, bb_inner.Min, bb_inner.Max, GetColorU32(col_source), grid_step, ImVec2(off, off), rounding);
        else
            window.DrawList.AddRectFilled(bb_inner.Min, bb_inner.Max, GetColorU32(col_source), rounding);
    }
    RenderNavHighlight(bb, id);
    if ((flags & ImGuiColorEditFlags.NoBorder) == 0)
    {
        if (g.Style.FrameBorderSize > 0.0f)
            RenderFrameBorder(bb.Min, bb.Max, rounding);
        else
            window.DrawList.AddRect(bb.Min, bb.Max, GetColorU32(ImGuiCol.FrameBg), rounding); // Color button are often in need of some sort of border
    }

    // Drag and Drop Source
    // NB: The ActiveId test is merely an optional micro-optimization, BeginDragDropSource() does the same test.
    if (g.ActiveId == id && !(flags & ImGuiColorEditFlags.NoDragDrop) && BeginDragDropSource())
    {
        if (flags & ImGuiColorEditFlags.NoAlpha)
            SetDragDropPayload(IMGUI_PAYLOAD_TYPE_COLOR_3F, &col_rgb, sizeof!(float) * 3, ImGuiCond.Once);
        else
            SetDragDropPayload(IMGUI_PAYLOAD_TYPE_COLOR_4F, &col_rgb, sizeof!(float) * 4, ImGuiCond.Once);
        ColorButton(desc_id, col, flags);
        SameLine();
        TextEx("Color");
        EndDragDropSource();
    }

    // Tooltip
    if (!(flags & ImGuiColorEditFlags.NoTooltip) && hovered)
        ColorTooltip(desc_id, &col.x, flags & (ImGuiColorEditFlags.InputMask_ | ImGuiColorEditFlags.NoAlpha | ImGuiColorEditFlags.AlphaPreview | ImGuiColorEditFlags.AlphaPreviewHalf));

    return pressed;
}

// Initialize/override default color options
void SetColorEditOptions(ImGuiColorEditFlags flags)
{
    ImGuiContext* g = GImGui;
    if ((flags & ImGuiColorEditFlags.DisplayMask_) == 0)
        flags |= ImGuiColorEditFlags.DefaultOptions_ & ImGuiColorEditFlags.DisplayMask_;
    if ((flags & ImGuiColorEditFlags.DataTypeMask_) == 0)
        flags |= ImGuiColorEditFlags.DefaultOptions_ & ImGuiColorEditFlags.DataTypeMask_;
    if ((flags & ImGuiColorEditFlags.PickerMask_) == 0)
        flags |= ImGuiColorEditFlags.DefaultOptions_ & ImGuiColorEditFlags.PickerMask_;
    if ((flags & ImGuiColorEditFlags.InputMask_) == 0)
        flags |= ImGuiColorEditFlags.DefaultOptions_ & ImGuiColorEditFlags.InputMask_;
    IM_ASSERT(ImIsPowerOfTwo(cast(int)(flags & ImGuiColorEditFlags.DisplayMask_)));    // Check only 1 option is selected
    IM_ASSERT(ImIsPowerOfTwo(cast(int)(flags & ImGuiColorEditFlags.DataTypeMask_)));   // Check only 1 option is selected
    IM_ASSERT(ImIsPowerOfTwo(cast(int)(flags & ImGuiColorEditFlags.PickerMask_)));     // Check only 1 option is selected
    IM_ASSERT(ImIsPowerOfTwo(cast(int)(flags & ImGuiColorEditFlags.InputMask_)));      // Check only 1 option is selected
    g.ColorEditOptions = flags;
}

// Note: only access 3 floats if ImGuiColorEditFlags_NoAlpha flag is set.
void ColorTooltip(string text, const float* col, ImGuiColorEditFlags flags)
{
    ImGuiContext* g = GImGui;

    BeginTooltipEx(ImGuiWindowFlags.None, ImGuiTooltipFlags.OverridePreviousTooltip);
    string text_end = text !is NULL ? FindRenderedTextEnd(text) : text;
    if (text_end.length > 0)
    {
        TextEx(text_end);
        Separator();
    }

    ImVec2 sz = ImVec2(g.FontSize * 3 + g.Style.FramePadding.y * 2, g.FontSize * 3 + g.Style.FramePadding.y * 2);
    ImVec4 cf = ImVec4(col[0], col[1], col[2], (flags & ImGuiColorEditFlags.NoAlpha) ? 1.0f : col[3]);
    int cr = IM_F32_TO_INT8_SAT(col[0]), cg = IM_F32_TO_INT8_SAT(col[1]), cb = IM_F32_TO_INT8_SAT(col[2]), ca = (flags & ImGuiColorEditFlags.NoAlpha) ? 255 : IM_F32_TO_INT8_SAT(col[3]);
    ColorButton("##preview", cf, (flags & (ImGuiColorEditFlags.InputMask_ | ImGuiColorEditFlags.NoAlpha | ImGuiColorEditFlags.AlphaPreview | ImGuiColorEditFlags.AlphaPreviewHalf)) | ImGuiColorEditFlags.NoTooltip, sz);
    SameLine();
    if ((flags & ImGuiColorEditFlags.InputRGB) || !(flags & ImGuiColorEditFlags.InputMask_))
    {
        if (flags & ImGuiColorEditFlags.NoAlpha)
            Text("#%02X%02X%02X\nR: %d, G: %d, B: %d\n(%.3f, %.3f, %.3f)", cr, cg, cb, cr, cg, cb, col[0], col[1], col[2]);
        else
            Text("#%02X%02X%02X%02X\nR:%d, G:%d, B:%d, A:%d\n(%.3f, %.3f, %.3f, %.3f)", cr, cg, cb, ca, cr, cg, cb, ca, col[0], col[1], col[2], col[3]);
    }
    else if (flags & ImGuiColorEditFlags.InputHSV)
    {
        if (flags & ImGuiColorEditFlags.NoAlpha)
            Text("H: %.3f, S: %.3f, V: %.3f", col[0], col[1], col[2]);
        else
            Text("H: %.3f, S: %.3f, V: %.3f, A: %.3f", col[0], col[1], col[2], col[3]);
    }
    EndTooltip();
}

void ColorEditOptionsPopup(const float* col, ImGuiColorEditFlags flags)
{
    bool allow_opt_inputs = !(flags & ImGuiColorEditFlags.DisplayMask_);
    bool allow_opt_datatype = !(flags & ImGuiColorEditFlags.DataTypeMask_);
    if ((!allow_opt_inputs && !allow_opt_datatype) || !BeginPopup("context"))
        return;
    ImGuiContext* g = GImGui;
    ImGuiColorEditFlags opts = g.ColorEditOptions;
    if (allow_opt_inputs)
    {
        if (RadioButton("RGB", (opts & ImGuiColorEditFlags.DisplayRGB) != 0)) opts = (opts & ~ImGuiColorEditFlags.DisplayMask_) | ImGuiColorEditFlags.DisplayRGB;
        if (RadioButton("HSV", (opts & ImGuiColorEditFlags.DisplayHSV) != 0)) opts = (opts & ~ImGuiColorEditFlags.DisplayMask_) | ImGuiColorEditFlags.DisplayHSV;
        if (RadioButton("Hex", (opts & ImGuiColorEditFlags.DisplayHex) != 0)) opts = (opts & ~ImGuiColorEditFlags.DisplayMask_) | ImGuiColorEditFlags.DisplayHex;
    }
    if (allow_opt_datatype)
    {
        if (allow_opt_inputs) Separator();
        if (RadioButton("0..255",     (opts & ImGuiColorEditFlags.Uint8) != 0)) opts = (opts & ~ImGuiColorEditFlags.DataTypeMask_) | ImGuiColorEditFlags.Uint8;
        if (RadioButton("0.00..1.00", (opts & ImGuiColorEditFlags.Float) != 0)) opts = (opts & ~ImGuiColorEditFlags.DataTypeMask_) | ImGuiColorEditFlags.Float;
    }

    if (allow_opt_inputs || allow_opt_datatype)
        Separator();
    if (Button("Copy as..", ImVec2(-1, 0)))
        OpenPopup("Copy");
    if (BeginPopup("Copy"))
    {
        int cr = IM_F32_TO_INT8_SAT(col[0]), cg = IM_F32_TO_INT8_SAT(col[1]), cb = IM_F32_TO_INT8_SAT(col[2]), ca = (flags & ImGuiColorEditFlags.NoAlpha) ? 255 : IM_F32_TO_INT8_SAT(col[3]);
        char[64] buf;
        int length = ImFormatString(buf, "(%.3ff, %.3ff, %.3ff, %.3ff)", col[0], col[1], col[2], (flags & ImGuiColorEditFlags.NoAlpha) ? 1.0f : col[3]);
        if (Selectable(cast(string)buf[0..length]))
            SetClipboardText(cast(string)buf[0..length]);
        length = ImFormatString(buf, "(%d,%d,%d,%d)", cr, cg, cb, ca);
        if (Selectable(cast(string)buf[0..length]))
            SetClipboardText(cast(string)buf[0..length]);
        length = ImFormatString(buf, "#%02X%02X%02X", cr, cg, cb);
        if (Selectable(cast(string)buf[0..length]))
            SetClipboardText(cast(string)buf[0..length]);
        if (!(flags & ImGuiColorEditFlags.NoAlpha))
        {
            length = ImFormatString(buf, "#%02X%02X%02X%02X", cr, cg, cb, ca);
            if (Selectable(cast(string)buf[0..length]))
                SetClipboardText(cast(string)buf[0..length]);
        }
        EndPopup();
    }

    g.ColorEditOptions = opts;
    EndPopup();
}

void ColorPickerOptionsPopup(const float* ref_col, ImGuiColorEditFlags flags)
{
    bool allow_opt_picker = !(flags & ImGuiColorEditFlags.PickerMask_);
    bool allow_opt_alpha_bar = !(flags & ImGuiColorEditFlags.NoAlpha) && !(flags & ImGuiColorEditFlags.AlphaBar);
    if ((!allow_opt_picker && !allow_opt_alpha_bar) || !BeginPopup("context"))
        return;
    ImGuiContext* g = GImGui;
    if (allow_opt_picker)
    {
        ImVec2 picker_size = ImVec2(g.FontSize * 8, ImMax(g.FontSize * 8 - (GetFrameHeight() + g.Style.ItemInnerSpacing.x), 1.0f)); // FIXME: Picker size copied from main picker function
        PushItemWidth(picker_size.x);
        for (int picker_type = 0; picker_type < 2; picker_type++)
        {
            // Draw small/thumbnail version of each picker type (over an invisible button for selection)
            if (picker_type > 0) Separator();
            PushID(picker_type);
            ImGuiColorEditFlags picker_flags = ImGuiColorEditFlags.NoInputs | ImGuiColorEditFlags.NoOptions | ImGuiColorEditFlags.NoLabel | ImGuiColorEditFlags.NoSidePreview | (flags & ImGuiColorEditFlags.NoAlpha);
            if (picker_type == 0) picker_flags |= ImGuiColorEditFlags.PickerHueBar;
            if (picker_type == 1) picker_flags |= ImGuiColorEditFlags.PickerHueWheel;
            ImVec2 backup_pos = GetCursorScreenPos();
            if (Selectable("##selectable", false, ImGuiSelectableFlags.None, picker_size)) // By default, Selectable() is closing popup
                g.ColorEditOptions = (g.ColorEditOptions & ~ImGuiColorEditFlags.PickerMask_) | (picker_flags & ImGuiColorEditFlags.PickerMask_);
            SetCursorScreenPos(backup_pos);
            ImVec4 previewing_ref_col;
            memcpy(&previewing_ref_col, ref_col, sizeof!(float) * (picker_flags & ImGuiColorEditFlags.NoAlpha ? 3 : 4));
            ColorPicker4("##previewing_picker", previewing_ref_col.array(), picker_flags);
            PopID();
        }
        PopItemWidth();
    }
    if (allow_opt_alpha_bar)
    {
        if (allow_opt_picker) Separator();
        CheckboxFlags("Alpha Bar", &g.ColorEditOptions, ImGuiColorEditFlags.AlphaBar);
    }
    EndPopup();
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: TreeNode, CollapsingHeader, etc.
//-------------------------------------------------------------------------
// - TreeNode()
// - TreeNodeV()
// - TreeNodeEx()
// - TreeNodeExV()
// - TreeNodeBehavior() [Internal]
// - TreePush()
// - TreePop()
// - GetTreeNodeToLabelSpacing()
// - SetNextItemOpen()
// - CollapsingHeader()
//-------------------------------------------------------------------------

bool TreeNode(A...)(string str_id, string fmt, A a)
{
    mixin va_start!a;
    bool is_open = TreeNodeExV(str_id, ImGuiTreeNodeFlags.None, fmt, va_args);
    va_end(va_args);
    return is_open;
}

bool TreeNode(A...)(const void* ptr_id, string fmt, A a)
{
    mixin va_start!a;
    bool is_open = TreeNodeExV(ptr_id, ImGuiTreeNodeFlags.None, fmt, va_args);
    va_end(va_args);
    return is_open;
}

bool TreeNode(string label)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;
    return TreeNodeBehavior(window.GetID(label), ImGuiTreeNodeFlags.None, label);
}

bool TreeNodeV(string str_id, string fmt, va_list args)
{
    return TreeNodeExV(str_id, ImGuiTreeNodeFlags.None, fmt, args);
}

bool TreeNodeV(const void* ptr_id, string fmt, va_list args)
{
    return TreeNodeExV(ptr_id, ImGuiTreeNodeFlags.None, fmt, args);
}

bool TreeNodeEx(string label, ImGuiTreeNodeFlags flags = ImGuiTreeNodeFlags.None)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    return TreeNodeBehavior(window.GetID(label), flags, label);
}

bool TreeNodeEx(A...)(string str_id, ImGuiTreeNodeFlags flags, string fmt, A a)
{
    mixin va_start!a;
    bool is_open = TreeNodeExV(str_id, flags, fmt, va_args);
    va_end(va_args);
    return is_open;
}

bool TreeNodeEx(A...)(const void* ptr_id, ImGuiTreeNodeFlags flags, string fmt, A a)
{
    mixin va_start!a;
    bool is_open = TreeNodeExV(ptr_id, flags, fmt, va_args);
    va_end(va_args);
    return is_open;
}

bool TreeNodeExV(string str_id, ImGuiTreeNodeFlags flags, string fmt, va_list args)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    ImGuiContext* g = GImGui;
    int label_end = ImFormatStringV(g.TempBuffer, fmt, args);
    return TreeNodeBehavior(window.GetID(str_id), flags, cast(string)g.TempBuffer[0..label_end]);
}

bool TreeNodeExV(const void* ptr_id, ImGuiTreeNodeFlags flags, string fmt, va_list args)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    ImGuiContext* g = GImGui;
    int label_end = ImFormatStringV(g.TempBuffer, fmt, args);
    return TreeNodeBehavior(window.GetID(ptr_id), flags, cast(string)g.TempBuffer[0..label_end]);
}

bool TreeNodeBehaviorIsOpen(ImGuiID id, ImGuiTreeNodeFlags flags = ImGuiTreeNodeFlags.None)
{
    if (flags & ImGuiTreeNodeFlags.Leaf)
        return true;

    // We only write to the tree storage if the user clicks (or explicitly use the SetNextItemOpen function)
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;
    ImGuiStorage* storage = window.DC.StateStorage;

    bool is_open;
    if (g.NextItemData.Flags & ImGuiNextItemDataFlags.HasOpen)
    {
        if (g.NextItemData.OpenCond & ImGuiCond.Always)
        {
            is_open = g.NextItemData.OpenVal;
            storage.SetInt(id, is_open);
        }
        else
        {
            // We treat ImGuiCond_Once and ImGuiCond_FirstUseEver the same because tree node state are not saved persistently.
            const int stored_value = storage.GetInt(id, -1);
            if (stored_value == -1)
            {
                is_open = g.NextItemData.OpenVal;
                storage.SetInt(id, is_open);
            }
            else
            {
                is_open = stored_value != 0;
            }
        }
    }
    else
    {
        is_open = storage.GetInt(id, (flags & ImGuiTreeNodeFlags.DefaultOpen) ? 1 : 0) != 0;
    }

    // When logging is enabled, we automatically expand tree nodes (but *NOT* collapsing headers.. seems like sensible behavior).
    // NB- If we are above max depth we still allow manually opened nodes to be logged.
    if (g.LogEnabled && !(flags & ImGuiTreeNodeFlags.NoAutoOpenOnLog) && (window.DC.TreeDepth - g.LogDepthRef) < g.LogDepthToExpand)
        is_open = true;

    return is_open;
}

bool TreeNodeBehavior(ImGuiID id, ImGuiTreeNodeFlags flags, string label)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    ImGuiContext* g = GImGui;
    const ImGuiStyle* style = &g.Style;
    const bool display_frame = (flags & ImGuiTreeNodeFlags.Framed) != 0;
    const ImVec2 padding = (display_frame || (flags & ImGuiTreeNodeFlags.FramePadding)) ? style.FramePadding : ImVec2(style.FramePadding.x, ImMin(window.DC.CurrLineTextBaseOffset, style.FramePadding.y));

    string label_end = FindRenderedTextEnd(label);
    const ImVec2 label_size = CalcTextSize(label_end, false);

    // We vertically grow up to current line height up the typical widget height.
    const float frame_height = ImMax(ImMin(window.DC.CurrLineSize.y, g.FontSize + style.FramePadding.y * 2), label_size.y + padding.y * 2);
    ImRect frame_bb;
    frame_bb.Min.x = (flags & ImGuiTreeNodeFlags.SpanFullWidth) ? window.WorkRect.Min.x : window.DC.CursorPos.x;
    frame_bb.Min.y = window.DC.CursorPos.y;
    frame_bb.Max.x = window.WorkRect.Max.x;
    frame_bb.Max.y = window.DC.CursorPos.y + frame_height;
    if (display_frame)
    {
        // Framed header expand a little outside the default padding, to the edge of InnerClipRect
        // (FIXME: May remove this at some point and make InnerClipRect align with WindowPadding.x instead of WindowPadding.x*0.5f)
        frame_bb.Min.x -= IM_FLOOR(window.WindowPadding.x * 0.5f - 1.0f);
        frame_bb.Max.x += IM_FLOOR(window.WindowPadding.x * 0.5f);
    }

    const float text_offset_x = g.FontSize + (display_frame ? padding.x * 3 : padding.x * 2);           // Collapser arrow width + Spacing
    const float text_offset_y = ImMax(padding.y, window.DC.CurrLineTextBaseOffset);                    // Latch before ItemSize changes it
    const float text_width = g.FontSize + (label_size.x > 0.0f ? label_size.x + padding.x * 2 : 0.0f);  // Include collapser
    ImVec2 text_pos = ImVec2(window.DC.CursorPos.x + text_offset_x, window.DC.CursorPos.y + text_offset_y);
    ItemSize(ImVec2(text_width, frame_height), padding.y);

    // For regular tree nodes, we arbitrary allow to click past 2 worth of ItemSpacing
    ImRect interact_bb = frame_bb;
    if (!display_frame && (flags & (ImGuiTreeNodeFlags.SpanAvailWidth | ImGuiTreeNodeFlags.SpanFullWidth)) == 0)
        interact_bb.Max.x = frame_bb.Min.x + text_width + style.ItemSpacing.x * 2.0f;

    // Store a flag for the current depth to tell if we will allow closing this node when navigating one of its child.
    // For this purpose we essentially compare if g.NavIdIsAlive went from 0 to 1 between TreeNode() and TreePop().
    // This is currently only support 32 level deep and we are fine with (1 << Depth) overflowing into a zero.
    const bool is_leaf = (flags & ImGuiTreeNodeFlags.Leaf) != 0;
    bool is_open = TreeNodeBehaviorIsOpen(id, flags);
    if (is_open && !g.NavIdIsAlive && (flags & ImGuiTreeNodeFlags.NavLeftJumpsBackHere) && !(flags & ImGuiTreeNodeFlags.NoTreePushOnOpen))
        window.DC.TreeJumpToParentOnPopMask |= (1 << window.DC.TreeDepth);

    bool item_add = ItemAdd(interact_bb, id);
    g.LastItemData.StatusFlags |= ImGuiItemStatusFlags.HasDisplayRect;
    g.LastItemData.DisplayRect = frame_bb;

    if (!item_add)
    {
        if (is_open && !(flags & ImGuiTreeNodeFlags.NoTreePushOnOpen))
            TreePushOverrideID(id);
        IMGUI_TEST_ENGINE_ITEM_INFO(g.LastItemData.ID, label, g.LastItemData.StatusFlags | (is_leaf ? ImGuiItemStatusFlags.None : ImGuiItemStatusFlags.Openable) | (is_open ? ImGuiItemStatusFlags.Opened : ImGuiItemStatusFlags.None));
        return is_open;
    }

    ImGuiButtonFlags button_flags = ImGuiButtonFlags.None;
    if (flags & ImGuiTreeNodeFlags.AllowItemOverlap)
        button_flags |= ImGuiButtonFlags.AllowItemOverlap;
    if (!is_leaf)
        button_flags |= ImGuiButtonFlags.PressedOnDragDropHold;

    // We allow clicking on the arrow section with keyboard modifiers held, in order to easily
    // allow browsing a tree while preserving selection with code implementing multi-selection patterns.
    // When clicking on the rest of the tree node we always disallow keyboard modifiers.
    const float arrow_hit_x1 = (text_pos.x - text_offset_x) - style.TouchExtraPadding.x;
    const float arrow_hit_x2 = (text_pos.x - text_offset_x) + (g.FontSize + padding.x * 2.0f) + style.TouchExtraPadding.x;
    const bool is_mouse_x_over_arrow = (g.IO.MousePos.x >= arrow_hit_x1 && g.IO.MousePos.x < arrow_hit_x2);
    if (window != g.HoveredWindow || !is_mouse_x_over_arrow)
        button_flags |= ImGuiButtonFlags.NoKeyModifiers;

    // Open behaviors can be altered with the _OpenOnArrow and _OnOnDoubleClick flags.
    // Some alteration have subtle effects (e.g. toggle on MouseUp vs MouseDown events) due to requirements for multi-selection and drag and drop support.
    // - Single-click on label = Toggle on MouseUp (default, when _OpenOnArrow=0)
    // - Single-click on arrow = Toggle on MouseDown (when _OpenOnArrow=0)
    // - Single-click on arrow = Toggle on MouseDown (when _OpenOnArrow=1)
    // - Double-click on label = Toggle on MouseDoubleClick (when _OpenOnDoubleClick=1)
    // - Double-click on arrow = Toggle on MouseDoubleClick (when _OpenOnDoubleClick=1 and _OpenOnArrow=0)
    // It is rather standard that arrow click react on Down rather than Up.
    // We set ImGuiButtonFlags_PressedOnClickRelease on OpenOnDoubleClick because we want the item to be active on the initial MouseDown in order for drag and drop to work.
    if (is_mouse_x_over_arrow)
        button_flags |= ImGuiButtonFlags.PressedOnClick;
    else if (flags & ImGuiTreeNodeFlags.OpenOnDoubleClick)
        button_flags |= ImGuiButtonFlags.PressedOnClickRelease | ImGuiButtonFlags.PressedOnDoubleClick;
    else
        button_flags |= ImGuiButtonFlags.PressedOnClickRelease;

    bool selected = (flags & ImGuiTreeNodeFlags.Selected) != 0;
    const bool was_selected = selected;

    bool hovered, held;
    bool pressed = ButtonBehavior(interact_bb, id, &hovered, &held, button_flags);
    bool toggled = false;
    if (!is_leaf)
    {
        if (pressed && g.DragDropHoldJustPressedId != id)
        {
            if ((flags & (ImGuiTreeNodeFlags.OpenOnArrow | ImGuiTreeNodeFlags.OpenOnDoubleClick)) == 0 || (g.NavActivateId == id))
                toggled = true;
            if (flags & ImGuiTreeNodeFlags.OpenOnArrow)
                toggled |= is_mouse_x_over_arrow && !g.NavDisableMouseHover; // Lightweight equivalent of IsMouseHoveringRect() since ButtonBehavior() already did the job
            if ((flags & ImGuiTreeNodeFlags.OpenOnDoubleClick) && g.IO.MouseDoubleClicked[0])
                toggled = true;
        }
        else if (pressed && g.DragDropHoldJustPressedId == id)
        {
            IM_ASSERT(button_flags & ImGuiButtonFlags.PressedOnDragDropHold);
            if (!is_open) // When using Drag and Drop "hold to open" we keep the node highlighted after opening, but never close it again.
                toggled = true;
        }

        if (g.NavId == id && g.NavMoveRequest && g.NavMoveDir == ImGuiDir.Left && is_open)
        {
            toggled = true;
            NavMoveRequestCancel();
        }
        if (g.NavId == id && g.NavMoveRequest && g.NavMoveDir == ImGuiDir.Right && !is_open) // If there's something upcoming on the line we may want to give it the priority?
        {
            toggled = true;
            NavMoveRequestCancel();
        }

        if (toggled)
        {
            is_open = !is_open;
            window.DC.StateStorage.SetInt(id, is_open);
            g.LastItemData.StatusFlags |= ImGuiItemStatusFlags.ToggledOpen;
        }
    }
    if (flags & ImGuiTreeNodeFlags.AllowItemOverlap)
        SetItemAllowOverlap();

    // In this branch, TreeNodeBehavior() cannot toggle the selection so this will never trigger.
    if (selected != was_selected) //-V547
        g.LastItemData.StatusFlags |= ImGuiItemStatusFlags.ToggledSelection;

    // Render
    const ImU32 text_col = GetColorU32(ImGuiCol.Text);
    ImGuiNavHighlightFlags nav_highlight_flags = ImGuiNavHighlightFlags.TypeThin;
    if (display_frame)
    {
        // Framed type
        const ImU32 bg_col = GetColorU32((held && hovered) ? ImGuiCol.HeaderActive : hovered ? ImGuiCol.HeaderHovered : ImGuiCol.Header);
        RenderFrame(frame_bb.Min, frame_bb.Max, bg_col, true, style.FrameRounding);
        RenderNavHighlight(frame_bb, id, nav_highlight_flags);
        if (flags & ImGuiTreeNodeFlags.Bullet)
            RenderBullet(window.DrawList, ImVec2(text_pos.x - text_offset_x * 0.60f, text_pos.y + g.FontSize * 0.5f), text_col);
        else if (!is_leaf)
            RenderArrow(window.DrawList, ImVec2(text_pos.x - text_offset_x + padding.x, text_pos.y), text_col, is_open ? ImGuiDir.Down : ImGuiDir.Right, 1.0f);
        else // Leaf without bullet, left-adjusted text
            text_pos.x -= text_offset_x;
        if (flags & ImGuiTreeNodeFlags.ClipLabelForTrailingButton)
            frame_bb.Max.x -= g.FontSize + style.FramePadding.x;

        if (g.LogEnabled)
            LogSetNextTextDecoration("###", "###");
        RenderTextClipped(text_pos, frame_bb.Max, label_end, &label_size);
    }
    else
    {
        // Unframed typed for tree nodes
        if (hovered || selected)
        {
            const ImU32 bg_col = GetColorU32((held && hovered) ? ImGuiCol.HeaderActive : hovered ? ImGuiCol.HeaderHovered : ImGuiCol.Header);
            RenderFrame(frame_bb.Min, frame_bb.Max, bg_col, false);
        }
        RenderNavHighlight(frame_bb, id, nav_highlight_flags);
        if (flags & ImGuiTreeNodeFlags.Bullet)
            RenderBullet(window.DrawList, ImVec2(text_pos.x - text_offset_x * 0.5f, text_pos.y + g.FontSize * 0.5f), text_col);
        else if (!is_leaf)
            RenderArrow(window.DrawList, ImVec2(text_pos.x - text_offset_x + padding.x, text_pos.y + g.FontSize * 0.15f), text_col, is_open ? ImGuiDir.Down : ImGuiDir.Right, 0.70f);
        if (g.LogEnabled)
            LogSetNextTextDecoration(">", NULL);
        RenderText(text_pos, label_end, false);
    }

    if (is_open && !(flags & ImGuiTreeNodeFlags.NoTreePushOnOpen))
        TreePushOverrideID(id);
    IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags | (is_leaf ? ImGuiItemStatusFlags.None : ImGuiItemStatusFlags.Openable) | (is_open ? ImGuiItemStatusFlags.Opened : ImGuiItemStatusFlags.None));
    return is_open;
}

void TreePush(string str_id)
{
    ImGuiWindow* window = GetCurrentWindow();
    Indent();
    window.DC.TreeDepth++;
    PushID(str_id ? str_id : "#TreePush");
}

void TreePush(const void* ptr_id = NULL)
{
    ImGuiWindow* window = GetCurrentWindow();
    Indent();
    window.DC.TreeDepth++;
    PushID(ptr_id ? ptr_id : cast(const void*)"#TreePush".ptr);
}

void TreePushOverrideID(ImGuiID id)
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;
    Indent();
    window.DC.TreeDepth++;
    window.IDStack.push_back(id);
}

void TreePop()
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;
    Unindent();

    window.DC.TreeDepth--;
    ImU32 tree_depth_mask = (1 << window.DC.TreeDepth);

    // Handle Left arrow to move to parent tree node (when ImGuiTreeNodeFlags_NavLeftJumpsBackHere is enabled)
    if (g.NavMoveDir == ImGuiDir.Left && g.NavWindow == window && NavMoveRequestButNoResultYet())
        if (g.NavIdIsAlive && (window.DC.TreeJumpToParentOnPopMask & tree_depth_mask))
        {
            SetNavID(window.IDStack.back(), g.NavLayer, 0, ImRect());
            NavMoveRequestCancel();
        }
    window.DC.TreeJumpToParentOnPopMask &= tree_depth_mask - 1;

    IM_ASSERT(window.IDStack.Size > 1); // There should always be 1 element in the IDStack (pushed during window creation). If this triggers you called TreePop/PopID too much.
    PopID();
}

// Horizontal distance preceding label when using TreeNode() or Bullet()
float GetTreeNodeToLabelSpacing()
{
    ImGuiContext* g = GImGui;
    return g.FontSize + (g.Style.FramePadding.x * 2.0f);
}

// Set next TreeNode/CollapsingHeader open state.
void SetNextItemOpen(bool is_open, ImGuiCond cond = ImGuiCond.None)
{
    ImGuiContext* g = GImGui;
    if (g.CurrentWindow.SkipItems)
        return;
    g.NextItemData.Flags |= ImGuiNextItemDataFlags.HasOpen;
    g.NextItemData.OpenVal = is_open;
    g.NextItemData.OpenCond = cond ? cond : ImGuiCond.Always;
}

// CollapsingHeader returns true when opened but do not indent nor push into the ID stack (because of the ImGuiTreeNodeFlags_NoTreePushOnOpen flag).
// This is basically the same as calling TreeNodeEx(label, ImGuiTreeNodeFlags_CollapsingHeader). You can remove the _NoTreePushOnOpen flag if you want behavior closer to normal TreeNode().
bool CollapsingHeader(string label, ImGuiTreeNodeFlags flags = ImGuiTreeNodeFlags.None)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    return TreeNodeBehavior(window.GetID(label), flags | ImGuiTreeNodeFlags.CollapsingHeader, label);
}

// p_visible == NULL                        : regular collapsing header
// p_visible != NULL && *p_visible == true  : show a small close button on the corner of the header, clicking the button will set *p_visible = false
// p_visible != NULL && *p_visible == false : do not show the header at all
// Do not mistake this with the Open state of the header itself, which you can adjust with SetNextItemOpen() or ImGuiTreeNodeFlags_DefaultOpen.
bool CollapsingHeader(string label, bool* p_visible, ImGuiTreeNodeFlags flags = ImGuiTreeNodeFlags.None)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    if (p_visible && !*p_visible)
        return false;

    ImGuiID id = window.GetID(label);
    flags |= ImGuiTreeNodeFlags.CollapsingHeader;
    if (p_visible)
        flags |= ImGuiTreeNodeFlags.AllowItemOverlap | ImGuiTreeNodeFlags.ClipLabelForTrailingButton;
    bool is_open = TreeNodeBehavior(id, flags, label);
    if (p_visible != NULL)
    {
        // Create a small overlapping close button
        // FIXME: We can evolve this into user accessible helpers to add extra buttons on title bars, headers, etc.
        // FIXME: CloseButton can overlap into text, need find a way to clip the text somehow.
        ImGuiContext* g = GImGui;
        ImGuiLastItemData last_item_backup = g.LastItemData;
        float button_size = g.FontSize;
        float button_x = ImMax(g.LastItemData.Rect.Min.x, g.LastItemData.Rect.Max.x - g.Style.FramePadding.x * 2.0f - button_size);
        float button_y = g.LastItemData.Rect.Min.y;
        ImGuiID close_button_id = GetIDWithSeed("#CLOSE", id);
        if (CloseButton(close_button_id, ImVec2(button_x, button_y)))
            *p_visible = false;
        g.LastItemData = last_item_backup;
    }

    return is_open;
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: Selectable
//-------------------------------------------------------------------------
// - Selectable()
//-------------------------------------------------------------------------

// Tip: pass a non-visible label (e.g. "##hello") then you can use the space to draw other text or image.
// But you need to make sure the ID is unique, e.g. enclose calls in PushID/PopID or use ##unique_id.
// With this scheme, ImGuiSelectableFlags_SpanAllColumns and ImGuiSelectableFlags_AllowItemOverlap are also frequently used flags.
// FIXME: Selectable() with (size.x == 0.0f) and (SelectableTextAlign.x > 0.0f) followed by SameLine() is currently not supported.
bool Selectable(string label, bool selected = false, ImGuiSelectableFlags flags = ImGuiSelectableFlags.None, const ImVec2/*&*/ size_arg = ImVec2(0, 0))
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    ImGuiContext* g = GImGui;
    const ImGuiStyle* style = &g.Style;

    // Submit label or explicit size to ItemSize(), whereas ItemAdd() will submit a larger/spanning rectangle.
    ImGuiID id = window.GetID(label);
    ImVec2 label_size = CalcTextSize(label, true);
    ImVec2 size = ImVec2(size_arg.x != 0.0f ? size_arg.x : label_size.x, size_arg.y != 0.0f ? size_arg.y : label_size.y);
    ImVec2 pos = window.DC.CursorPos;
    pos.y += window.DC.CurrLineTextBaseOffset;
    ItemSize(size, 0.0f);

    // Fill horizontal space
    // We don't support (size < 0.0f) in Selectable() because the ItemSpacing extension would make explicitly right-aligned sizes not visibly match other widgets.
    const bool span_all_columns = (flags & ImGuiSelectableFlags.SpanAllColumns) != 0;
    const float min_x = span_all_columns ? window.ParentWorkRect.Min.x : pos.x;
    const float max_x = span_all_columns ? window.ParentWorkRect.Max.x : window.WorkRect.Max.x;
    if (size_arg.x == 0.0f || (flags & ImGuiSelectableFlags.SpanAvailWidth))
        size.x = ImMax(label_size.x, max_x - min_x);

    // Text stays at the submission position, but bounding box may be extended on both sides
    const ImVec2 text_min = pos;
    const ImVec2 text_max = ImVec2(min_x + size.x, pos.y + size.y);

    // Selectables are meant to be tightly packed together with no click-gap, so we extend their box to cover spacing between selectable.
    ImRect bb = ImRect(min_x, pos.y, text_max.x, text_max.y);
    if ((flags & ImGuiSelectableFlags.NoPadWithHalfSpacing) == 0)
    {
        const float spacing_x = span_all_columns ? 0.0f : style.ItemSpacing.x;
        const float spacing_y = style.ItemSpacing.y;
        const float spacing_L = IM_FLOOR(spacing_x * 0.50f);
        const float spacing_U = IM_FLOOR(spacing_y * 0.50f);
        bb.Min.x -= spacing_L;
        bb.Min.y -= spacing_U;
        bb.Max.x += (spacing_x - spacing_L);
        bb.Max.y += (spacing_y - spacing_U);
    }
    //if (g.IO.KeyCtrl) { GetForegroundDrawList()->AddRect(bb.Min, bb.Max, IM_COL32(0, 255, 0, 255)); }

    // Modify ClipRect for the ItemAdd(), faster than doing a PushColumnsBackground/PushTableBackground for every Selectable..
    const float backup_clip_rect_min_x = window.ClipRect.Min.x;
    const float backup_clip_rect_max_x = window.ClipRect.Max.x;
    if (span_all_columns)
    {
        window.ClipRect.Min.x = window.ParentWorkRect.Min.x;
        window.ClipRect.Max.x = window.ParentWorkRect.Max.x;
    }

    bool item_add;
    const bool disabled_item = (flags & ImGuiSelectableFlags.Disabled) != 0;
    if (disabled_item)
    {
        ImGuiItemFlags backup_item_flags = g.CurrentItemFlags;
        g.CurrentItemFlags |= ImGuiItemFlags.Disabled;
        item_add = ItemAdd(bb, id);
        g.CurrentItemFlags = backup_item_flags;
    }
    else
    {
        item_add = ItemAdd(bb, id);
    }

    if (span_all_columns)
    {
        window.ClipRect.Min.x = backup_clip_rect_min_x;
        window.ClipRect.Max.x = backup_clip_rect_max_x;
    }

    if (!item_add)
        return false;

    const bool disabled_global = (g.CurrentItemFlags & ImGuiItemFlags.Disabled) != 0;
    if (disabled_item && !disabled_global) // Only testing this as an optimization
        BeginDisabled(true);

    // FIXME: We can standardize the behavior of those two, we could also keep the fast path of override ClipRect + full push on render only,
    // which would be advantageous since most selectable are not selected.
    if (span_all_columns && window.DC.CurrentColumns)
        PushColumnsBackground();
    else if (span_all_columns && g.CurrentTable)
        TablePushBackgroundChannel();

    // We use NoHoldingActiveID on menus so user can click and _hold_ on a menu then drag to browse child entries
    ImGuiButtonFlags button_flags = ImGuiButtonFlags.None;
    if (flags & ImGuiSelectableFlags.NoHoldingActiveID) { button_flags |= ImGuiButtonFlags.NoHoldingActiveId; }
    if (flags & ImGuiSelectableFlags.SelectOnClick)     { button_flags |= ImGuiButtonFlags.PressedOnClick; }
    if (flags & ImGuiSelectableFlags.SelectOnRelease)   { button_flags |= ImGuiButtonFlags.PressedOnRelease; }
    if (flags & ImGuiSelectableFlags.AllowDoubleClick)  { button_flags |= ImGuiButtonFlags.PressedOnClickRelease | ImGuiButtonFlags.PressedOnDoubleClick; }
    if (flags & ImGuiSelectableFlags.AllowItemOverlap)  { button_flags |= ImGuiButtonFlags.AllowItemOverlap; }

    const bool was_selected = selected;
    bool hovered, held;
    bool pressed = ButtonBehavior(bb, id, &hovered, &held, button_flags);

    // Auto-select when moved into
    // - This will be more fully fleshed in the range-select branch
    // - This is not exposed as it won't nicely work with some user side handling of shift/control
    // - We cannot do 'if (g.NavJustMovedToId != id) { selected = false; pressed = was_selected; }' for two reasons
    //   - (1) it would require focus scope to be set, need exposing PushFocusScope() or equivalent (e.g. BeginSelection() calling PushFocusScope())
    //   - (2) usage will fail with clipped items
    //   The multi-select API aim to fix those issues, e.g. may be replaced with a BeginSelection() API.
    if ((flags & ImGuiSelectableFlags.SelectOnNav) && g.NavJustMovedToId != 0 && g.NavJustMovedToFocusScopeId == window.DC.NavFocusScopeIdCurrent)
        if (g.NavJustMovedToId == id)
            selected = pressed = true;

    // Update NavId when clicking or when Hovering (this doesn't happen on most widgets), so navigation can be resumed with gamepad/keyboard
    if (pressed || (hovered && (flags & ImGuiSelectableFlags.SetNavIdOnHover)))
    {
        if (!g.NavDisableMouseHover && g.NavWindow == window && g.NavLayer == window.DC.NavLayerCurrent)
        {
            SetNavID(id, window.DC.NavLayerCurrent, window.DC.NavFocusScopeIdCurrent, ImRect(bb.Min - window.Pos, bb.Max - window.Pos));
            g.NavDisableHighlight = true;
        }
    }
    if (pressed)
        MarkItemEdited(id);

    if (flags & ImGuiSelectableFlags.AllowItemOverlap)
        SetItemAllowOverlap();

    // In this branch, Selectable() cannot toggle the selection so this will never trigger.
    if (selected != was_selected) //-V547
        g.LastItemData.StatusFlags |= ImGuiItemStatusFlags.ToggledSelection;

    // Render
    if (held && (flags & ImGuiSelectableFlags.DrawHoveredWhenHeld))
        hovered = true;
    if (hovered || selected)
    {
        const ImU32 col = GetColorU32((held && hovered) ? ImGuiCol.HeaderActive : hovered ? ImGuiCol.HeaderHovered : ImGuiCol.Header);
        RenderFrame(bb.Min, bb.Max, col, false, 0.0f);
    }
    RenderNavHighlight(bb, id, ImGuiNavHighlightFlags.TypeThin | ImGuiNavHighlightFlags.NoRounding);

    if (span_all_columns && window.DC.CurrentColumns)
        PopColumnsBackground();
    else if (span_all_columns && g.CurrentTable)
        TablePopBackgroundChannel();

    RenderTextClipped(text_min, text_max, label, &label_size, style.SelectableTextAlign, &bb);

    // Automatically close popups
    if (pressed && (window.Flags & ImGuiWindowFlags.Popup) && !(flags & ImGuiSelectableFlags.DontClosePopups) && !(g.LastItemData.InFlags & ImGuiItemFlags.SelectableDontClosePopup))
        CloseCurrentPopup();

    if (disabled_item && !disabled_global)
        EndDisabled();

    IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags);
    return pressed; //-V1020
}

bool Selectable(string label, bool* p_selected, ImGuiSelectableFlags flags = ImGuiSelectableFlags.None, const ImVec2/*&*/ size_arg = ImVec2(0, 0))
{
    if (Selectable(label, *p_selected, flags, size_arg))
    {
        *p_selected = !*p_selected;
        return true;
    }
    return false;
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: ListBox
//-------------------------------------------------------------------------
// - BeginListBox()
// - EndListBox()
// - ListBox()
//-------------------------------------------------------------------------

// Tip: To have a list filling the entire window width, use size.x = -FLT_MIN and pass an non-visible label e.g. "##empty"
// Tip: If your vertical size is calculated from an item count (e.g. 10 * item_height) consider adding a fractional part to facilitate seeing scrolling boundaries (e.g. 10.25 * item_height).
bool BeginListBox(string label, const ImVec2/*&*/ size_arg = ImVec2(0, 0))
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    const ImGuiStyle* style = &g.Style;
    const ImGuiID id = GetID(label);
    const ImVec2 label_size = CalcTextSize(label, true);

    // Size default to hold ~7.25 items.
    // Fractional number of items helps seeing that we can scroll down/up without looking at scrollbar.
    ImVec2 size = ImFloor(CalcItemSize(size_arg, CalcItemWidth(), GetTextLineHeightWithSpacing() * 7.25f + style.FramePadding.y * 2.0f));
    ImVec2 frame_size = ImVec2(size.x, ImMax(size.y, label_size.y));
    ImRect frame_bb = ImRect(window.DC.CursorPos, window.DC.CursorPos + frame_size);
    ImRect bb = ImRect(frame_bb.Min, frame_bb.Max + ImVec2(label_size.x > 0.0f ? style.ItemInnerSpacing.x + label_size.x : 0.0f, 0.0f));
    g.NextItemData.ClearFlags();

    if (!IsRectVisible(bb.Min, bb.Max))
    {
        ItemSize(bb.GetSize(), style.FramePadding.y);
        ItemAdd(bb, 0, &frame_bb);
        return false;
    }

    // FIXME-OPT: We could omit the BeginGroup() if label_size.x but would need to omit the EndGroup() as well.
    BeginGroup();
    if (label_size.x > 0.0f)
    {
        ImVec2 label_pos = ImVec2(frame_bb.Max.x + style.ItemInnerSpacing.x, frame_bb.Min.y + style.FramePadding.y);
        RenderText(label_pos, label);
        window.DC.CursorMaxPos = ImMax(window.DC.CursorMaxPos, label_pos + label_size);
    }

    BeginChildFrame(id, frame_bb.GetSize());
    return true;
}

static if (!IMGUI_DISABLE_OBSOLETE_FUNCTIONS) {
// OBSOLETED in 1.81 (from February 2021)
bool ListBoxHeader(string label, int items_count, int height_in_items = -1)
{
    // If height_in_items == -1, default height is maximum 7.
    ImGuiContext* g = GImGui;
    float height_in_items_f = (height_in_items < 0 ? ImMin(items_count, 7) : height_in_items) + 0.25f;
    ImVec2 size;
    size.x = 0.0f;
    size.y = GetTextLineHeightWithSpacing() * height_in_items_f + g.Style.FramePadding.y * 2.0f;
    return BeginListBox(label, size);
}
}

void EndListBox()
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;
    IM_ASSERT((window.Flags & ImGuiWindowFlags.ChildWindow), "Mismatched BeginListBox/EndListBox calls. Did you test the return value of BeginListBox?");
    IM_UNUSED(window);

    EndChildFrame();
    EndGroup(); // This is only required to be able to do IsItemXXX query on the whole ListBox including label
}

bool ListBox(string label, int* current_item, string[] items, int height_items = -1)
{
    const bool value_changed = ListBox(label, current_item, &Items_ArrayGetter, &items, cast(int)items.length, height_items);
    return value_changed;
}

// This is merely a helper around BeginListBox(), EndListBox().
// Considering using those directly to submit custom data or store selection differently.
bool ListBox(string label, int* current_item, bool function(void* data, int idx, string* out_text) nothrow @nogc items_getter, void* data, int items_count, int height_in_items = -1)
{
    ImGuiContext* g = GImGui;

    // Calculate size from "height_in_items"
    if (height_in_items < 0)
        height_in_items = ImMin(items_count, 7);
    float height_in_items_f = height_in_items + 0.25f;
    ImVec2 size = ImVec2(0.0f, ImFloor(GetTextLineHeightWithSpacing() * height_in_items_f + g.Style.FramePadding.y * 2.0f));

    if (!BeginListBox(label, size))
        return false;

    // Assume all items have even height (= 1 line of text). If you need items of different height,
    // you can create a custom version of ListBox() in your code without using the clipper.
    bool value_changed = false;
    ImGuiListClipper clipper = ImGuiListClipper(false);
    clipper.Begin(items_count, GetTextLineHeightWithSpacing()); // We know exactly our line height here so we pass it as a minor optimization, but generally you don't need to.
    while (clipper.Step())
        for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
        {
            string item_text;
            if (!items_getter(data, i, &item_text))
                item_text = "*Unknown item*";

            PushID(i);
            const bool item_selected = (i == *current_item);
            if (Selectable(item_text, item_selected))
            {
                *current_item = i;
                value_changed = true;
            }
            if (item_selected)
                SetItemDefaultFocus();
            PopID();
        }
    EndListBox();

    if (value_changed)
        MarkItemEdited(g.LastItemData.ID);

    return value_changed;
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: PlotLines, PlotHistogram
//-------------------------------------------------------------------------
// - PlotEx() [Internal]
// - PlotLines()
// - PlotHistogram()
//-------------------------------------------------------------------------
// Plot/Graph widgets are not very good.
// Consider writing your own, or using a third-party one, see:
// - ImPlot https://github.com/epezent/implot
// - others https://github.com/ocornut/imgui/wiki/Useful-Extensions
//-------------------------------------------------------------------------

int PlotEx(ImGuiPlotType plot_type, string label, float function(void* data, int idx) nothrow @nogc values_getter, void* data, int values_count, int values_offset, string overlay_text, float scale_min, float scale_max, ImVec2 frame_size)
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return -1;

    const ImGuiStyle* style = &g.Style;
    const ImGuiID id = window.GetID(label);

    const ImVec2 label_size = CalcTextSize(label, true);
    if (frame_size.x == 0.0f)
        frame_size.x = CalcItemWidth();
    if (frame_size.y == 0.0f)
        frame_size.y = label_size.y + (style.FramePadding.y * 2);

    const ImRect frame_bb = ImRect(window.DC.CursorPos, window.DC.CursorPos + frame_size);
    const ImRect inner_bb = ImRect(frame_bb.Min + style.FramePadding, frame_bb.Max - style.FramePadding);
    const ImRect total_bb = ImRect(frame_bb.Min, frame_bb.Max + ImVec2(label_size.x > 0.0f ? style.ItemInnerSpacing.x + label_size.x : 0.0f, 0));
    ItemSize(total_bb, style.FramePadding.y);
    if (!ItemAdd(total_bb, 0, &frame_bb))
        return -1;
    const bool hovered = ItemHoverable(frame_bb, id);

    // Determine scale from values if not specified
    if (scale_min == FLT_MAX || scale_max == FLT_MAX)
    {
        float v_min = FLT_MAX;
        float v_max = -FLT_MAX;
        for (int i = 0; i < values_count; i++)
        {
            const float v = values_getter(data, i);
            if (v != v) // Ignore NaN values
                continue;
            v_min = ImMin(v_min, v);
            v_max = ImMax(v_max, v);
        }
        if (scale_min == FLT_MAX)
            scale_min = v_min;
        if (scale_max == FLT_MAX)
            scale_max = v_max;
    }

    RenderFrame(frame_bb.Min, frame_bb.Max, GetColorU32(ImGuiCol.FrameBg), true, style.FrameRounding);

    const int values_count_min = (plot_type == ImGuiPlotType.Lines) ? 2 : 1;
    int idx_hovered = -1;
    if (values_count >= values_count_min)
    {
        int res_w = ImMin(cast(int)frame_size.x, values_count) + ((plot_type == ImGuiPlotType.Lines) ? -1 : 0);
        int item_count = values_count + ((plot_type == ImGuiPlotType.Lines) ? -1 : 0);

        // Tooltip on hover
        if (hovered && inner_bb.Contains(g.IO.MousePos))
        {
            const float t = ImClamp((g.IO.MousePos.x - inner_bb.Min.x) / (inner_bb.Max.x - inner_bb.Min.x), 0.0f, 0.9999f);
            const int v_idx = cast(int)(t * item_count);
            IM_ASSERT(v_idx >= 0 && v_idx < values_count);

            const float v0 = values_getter(data, (v_idx + values_offset) % values_count);
            const float v1 = values_getter(data, (v_idx + 1 + values_offset) % values_count);
            if (plot_type == ImGuiPlotType.Lines)
                SetTooltip("%d: %8.4g\n%d: %8.4g", v_idx, v0, v_idx + 1, v1);
            else if (plot_type == ImGuiPlotType.Histogram)
                SetTooltip("%d: %8.4g", v_idx, v0);
            idx_hovered = v_idx;
        }

        const float t_step = 1.0f / cast(float)res_w;
        const float inv_scale = (scale_min == scale_max) ? 0.0f : (1.0f / (scale_max - scale_min));

        float v0 = values_getter(data, (0 + values_offset) % values_count);
        float t0 = 0.0f;
        ImVec2 tp0 = ImVec2( t0, 1.0f - ImSaturate((v0 - scale_min) * inv_scale) );                       // Point in the normalized space of our target rectangle
        float histogram_zero_line_t = (scale_min * scale_max < 0.0f) ? (-scale_min * inv_scale) : (scale_min < 0.0f ? 0.0f : 1.0f);   // Where does the zero line stands

        const ImU32 col_base = GetColorU32((plot_type == ImGuiPlotType.Lines) ? ImGuiCol.PlotLines : ImGuiCol.PlotHistogram);
        const ImU32 col_hovered = GetColorU32((plot_type == ImGuiPlotType.Lines) ? ImGuiCol.PlotLinesHovered : ImGuiCol.PlotHistogramHovered);

        for (int n = 0; n < res_w; n++)
        {
            const float t1 = t0 + t_step;
            const int v1_idx = cast(int)(t0 * item_count + 0.5f);
            IM_ASSERT(v1_idx >= 0 && v1_idx < values_count);
            const float v1 = values_getter(data, (v1_idx + values_offset + 1) % values_count);
            const ImVec2 tp1 = ImVec2( t1, 1.0f - ImSaturate((v1 - scale_min) * inv_scale) );

            // NB: Draw calls are merged together by the DrawList system. Still, we should render our batch are lower level to save a bit of CPU.
            ImVec2 pos0 = ImLerp(inner_bb.Min, inner_bb.Max, tp0);
            ImVec2 pos1 = ImLerp(inner_bb.Min, inner_bb.Max, (plot_type == ImGuiPlotType.Lines) ? tp1 : ImVec2(tp1.x, histogram_zero_line_t));
            if (plot_type == ImGuiPlotType.Lines)
            {
                window.DrawList.AddLine(pos0, pos1, idx_hovered == v1_idx ? col_hovered : col_base);
            }
            else if (plot_type == ImGuiPlotType.Histogram)
            {
                if (pos1.x >= pos0.x + 2.0f)
                    pos1.x -= 1.0f;
                window.DrawList.AddRectFilled(pos0, pos1, idx_hovered == v1_idx ? col_hovered : col_base);
            }

            t0 = t1;
            tp0 = tp1;
        }
    }

    // Text overlay
    if (overlay_text !is NULL)
        RenderTextClipped(ImVec2(frame_bb.Min.x, frame_bb.Min.y + style.FramePadding.y), frame_bb.Max, overlay_text, NULL, ImVec2(0.5f, 0.0f));

    if (label_size.x > 0.0f)
        RenderText(ImVec2(frame_bb.Max.x + style.ItemInnerSpacing.x, inner_bb.Min.y), label);

    // Return hovered index or -1 if none are hovered.
    // This is currently not exposed in the public API because we need a larger redesign of the whole thing, but in the short-term we are making it available in PlotEx().
    return idx_hovered;
}

struct ImGuiPlotArrayGetterData
{
    nothrow:
    @nogc:

    const float* Values;
    int Stride;

    this(const float* values, int stride) { Values = values; Stride = stride; }
}

static float Plot_ArrayGetter(void* data, int idx)
{
    ImGuiPlotArrayGetterData* plot_data = cast(ImGuiPlotArrayGetterData*)data;
    const float v = plot_data.Values[cast(size_t)idx * plot_data.Stride / sizeof!(float)];
    return v;
}

void PlotLines(string label, const float[] values, int values_offset = 0, string overlay_text = NULL, float scale_min = FLT_MAX, float scale_max = FLT_MAX, ImVec2 graph_size = ImVec2(0, 0), int stride = sizeof!(float))
{
    ImGuiPlotArrayGetterData data = ImGuiPlotArrayGetterData(values.ptr, stride);
    PlotEx(ImGuiPlotType.Lines, label, &Plot_ArrayGetter, cast(void*)&data, cast(int)(values.length * stride / sizeof!(float)), values_offset, overlay_text, scale_min, scale_max, graph_size);
}

void PlotLines(string label, const float* values, int values_count, int values_offset = 0, string overlay_text = NULL, float scale_min = FLT_MAX, float scale_max = FLT_MAX, ImVec2 graph_size = ImVec2(0, 0), int stride = sizeof!(float))
{
    ImGuiPlotArrayGetterData data = ImGuiPlotArrayGetterData(values, stride);
    PlotEx(ImGuiPlotType.Lines, label, &Plot_ArrayGetter, cast(void*)&data, cast(int)(values_count * stride / sizeof!(float)), values_offset, overlay_text, scale_min, scale_max, graph_size);
}

void PlotLines(string label, float function(void* data, int idx) nothrow @nogc values_getter, void* data, int values_count, int values_offset = 0, string overlay_text = NULL, float scale_min = FLT_MAX, float scale_max = FLT_MAX, ImVec2 graph_size = ImVec2(0, 0))
{
    PlotEx(ImGuiPlotType.Lines, label, values_getter, data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size);
}

void PlotHistogram(string label, const float[] values, int values_offset = 0, string overlay_text = NULL, float scale_min = FLT_MAX, float scale_max = FLT_MAX, ImVec2 graph_size = ImVec2(0, 0), int stride = sizeof!(float))
{
    ImGuiPlotArrayGetterData data = ImGuiPlotArrayGetterData(values.ptr, stride);
    PlotEx(ImGuiPlotType.Histogram, label, &Plot_ArrayGetter, cast(void*)&data, cast(int)(values.length * stride / sizeof!(float)), values_offset, overlay_text, scale_min, scale_max, graph_size);
}

void PlotHistogram(string label, const float* values, int values_count, int values_offset = 0, string overlay_text = NULL, float scale_min = FLT_MAX, float scale_max = FLT_MAX, ImVec2 graph_size = ImVec2(0, 0), int stride = sizeof!(float))
{
    ImGuiPlotArrayGetterData data = ImGuiPlotArrayGetterData(values, stride);
    PlotEx(ImGuiPlotType.Histogram, label, &Plot_ArrayGetter, cast(void*)&data, cast(int)(values_count * stride / sizeof!(float)), values_offset, overlay_text, scale_min, scale_max, graph_size);
}

void PlotHistogram(string label, float function(void* data, int idx) nothrow @nogc values_getter, void* data, int values_count, int values_offset = 0, string overlay_text = NULL, float scale_min = FLT_MAX, float scale_max = FLT_MAX, ImVec2 graph_size = ImVec2(0, 0))
{
    PlotEx(ImGuiPlotType.Histogram, label, values_getter, data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size);
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: Value helpers
// Those is not very useful, legacy API.
//-------------------------------------------------------------------------
// - Value()
//-------------------------------------------------------------------------

void Value(string prefix, bool b)
{
    Text("%s: %s", prefix, (b ? "true" : "false"));
}

void Value(string prefix, int v)
{
    Text("%s: %d", prefix, v);
}

void Value(string prefix, uint v)
{
    Text("%s: %d", prefix, v);
}

void Value(string prefix, float v, string float_format = NULL)
{
    if (float_format)
    {
        char[64] fmt;
        int index = ImFormatString(fmt, "%%s: %s", float_format);
        Text(cast(string)fmt[0..index], prefix, v);
    }
    else
    {
        Text("%s: %.3f", prefix, v);
    }
}

//-------------------------------------------------------------------------
// [SECTION] MenuItem, BeginMenu, EndMenu, etc.
//-------------------------------------------------------------------------
// - ImGuiMenuColumns [Internal]
// - BeginMenuBar()
// - EndMenuBar()
// - BeginMainMenuBar()
// - EndMainMenuBar()
// - BeginMenu()
// - EndMenu()
// - MenuItemEx() [Internal]
// - MenuItem()
//-------------------------------------------------------------------------

// D_IMGUI: Wrapper for ImGuiMenuColumns
struct ImGuiMenuColumns_Wrapper {

    nothrow:
    @nogc:

    ImGuiMenuColumns _data = ImGuiMenuColumns.init;
    alias _data this;

// Helpers for internal use
void Update(float spacing, bool window_reappearing)
{
    if (window_reappearing)
        memset(Widths, 0, sizeof(Widths));
    _data.Spacing = cast(ImU16)spacing;
    CalcNextTotalWidth(true);
    memset(Widths, 0, sizeof(Widths));
    TotalWidth = NextTotalWidth;
    NextTotalWidth = 0;
}

void CalcNextTotalWidth(bool update_offsets)
{
    ImU16 offset = 0;
    bool want_spacing = false;
    for (int i = 0; i < IM_ARRAYSIZE(Widths); i++)
    {
        ImU16 width = Widths[i];
        if (want_spacing && width > 0)
            offset += _data.Spacing;
        want_spacing |= (width > 0);
        if (update_offsets)
        {
            if (i == 1) { OffsetLabel = offset; }
            if (i == 2) { OffsetShortcut = offset; }
            if (i == 3) { OffsetMark = offset; }
        }
        offset += width;
    }
    NextTotalWidth = offset;
}

float DeclColumns(float w_icon, float w_label, float w_shortcut, float w_mark)
{
    Widths[0] = ImMax(Widths[0], cast(ImU16)w_icon);
    Widths[1] = ImMax(Widths[1], cast(ImU16)w_label);
    Widths[2] = ImMax(Widths[2], cast(ImU16)w_shortcut);
    Widths[3] = ImMax(Widths[3], cast(ImU16)w_mark);
    CalcNextTotalWidth(false);
    return cast(float)ImMax(TotalWidth, NextTotalWidth);
}

}

// FIXME: Provided a rectangle perhaps e.g. a BeginMenuBarEx() could be used anywhere..
// Currently the main responsibility of this function being to setup clip-rect + horizontal layout + menu navigation layer.
// Ideally we also want this to be responsible for claiming space out of the main window scrolling rectangle, in which case ImGuiWindowFlags_MenuBar will become unnecessary.
// Then later the same system could be used for multiple menu-bars, scrollbars, side-bars.
bool BeginMenuBar()
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;
    if (!(window.Flags & ImGuiWindowFlags.MenuBar))
        return false;

    IM_ASSERT(!window.DC.MenuBarAppending);
    BeginGroup(); // Backup position on layer 0 // FIXME: Misleading to use a group for that backup/restore
    PushID("##menubar");

    // We don't clip with current window clipping rectangle as it is already set to the area below. However we clip with window full rect.
    // We remove 1 worth of rounding to Max.x to that text in long menus and small windows don't tend to display over the lower-right rounded area, which looks particularly glitchy.
    ImRect bar_rect = window.MenuBarRect();
    ImRect clip_rect = ImRect(IM_ROUND(bar_rect.Min.x + window.WindowBorderSize), IM_ROUND(bar_rect.Min.y + window.WindowBorderSize), IM_ROUND(ImMax(bar_rect.Min.x, bar_rect.Max.x - ImMax(window.WindowRounding, window.WindowBorderSize))), IM_ROUND(bar_rect.Max.y));
    clip_rect.ClipWith(window.OuterRectClipped);
    PushClipRect(clip_rect.Min, clip_rect.Max, false);

    // We overwrite CursorMaxPos because BeginGroup sets it to CursorPos (essentially the .EmitItem hack in EndMenuBar() would need something analogous here, maybe a BeginGroupEx() with flags).
    window.DC.CursorPos = window.DC.CursorMaxPos = ImVec2(bar_rect.Min.x + window.DC.MenuBarOffset.x, bar_rect.Min.y + window.DC.MenuBarOffset.y);
    window.DC.LayoutType = ImGuiLayoutType.Horizontal;
    window.DC.NavLayerCurrent = ImGuiNavLayer.Menu;
    window.DC.MenuBarAppending = true;
    AlignTextToFramePadding();
    return true;
}

void EndMenuBar()
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return;
    ImGuiContext* g = GImGui;

    // Nav: When a move request within one of our child menu failed, capture the request to navigate among our siblings.
    if (NavMoveRequestButNoResultYet() && (g.NavMoveDir == ImGuiDir.Left || g.NavMoveDir == ImGuiDir.Right) && (g.NavWindow.Flags & ImGuiWindowFlags.ChildMenu))
    {
        ImGuiWindow* nav_earliest_child = g.NavWindow;
        while (nav_earliest_child.ParentWindow && (nav_earliest_child.ParentWindow.Flags & ImGuiWindowFlags.ChildMenu))
            nav_earliest_child = nav_earliest_child.ParentWindow;
        if (nav_earliest_child.ParentWindow == window && nav_earliest_child.DC.ParentLayoutType == ImGuiLayoutType.Horizontal && g.NavMoveRequestForward == ImGuiNavForward.None)
        {
            // To do so we claim focus back, restore NavId and then process the movement request for yet another frame.
            // This involve a one-frame delay which isn't very problematic in this situation. We could remove it by scoring in advance for multiple window (probably not worth the hassle/cost)
            const ImGuiNavLayer layer = ImGuiNavLayer.Menu;
            IM_ASSERT(window.DC.NavLayersActiveMaskNext & (1 << layer)); // Sanity check
            FocusWindow(window);
            SetNavID(window.NavLastIds[layer], layer, 0, window.NavRectRel[layer]);
            g.NavDisableHighlight = true; // Hide highlight for the current frame so we don't see the intermediary selection.
            g.NavDisableMouseHover = g.NavMousePosDirty = true;
            g.NavMoveRequestForward = ImGuiNavForward.ForwardQueued;
            NavMoveRequestCancel();
        }
    }

    // IM_MSVC_WARNING_SUPPRESS(6011); // Static Analysis false positive "warning C6011: Dereferencing NULL pointer 'window'"
    IM_ASSERT(window.Flags & ImGuiWindowFlags.MenuBar);
    IM_ASSERT(window.DC.MenuBarAppending);
    PopClipRect();
    PopID();
    window.DC.MenuBarOffset.x = window.DC.CursorPos.x - window.Pos.x; // Save horizontal position so next append can reuse it. This is kinda equivalent to a per-layer CursorPos.
    g.GroupStack.back().EmitItem = false;
    EndGroup(); // Restore position on layer 0
    window.DC.LayoutType = ImGuiLayoutType.Vertical;
    window.DC.NavLayerCurrent = ImGuiNavLayer.Main;
    window.DC.MenuBarAppending = false;
}

// Important: calling order matters!
// FIXME: Somehow overlapping with docking tech.
// FIXME: The "rect-cut" aspect of this could be formalized into a lower-level helper (rect-cut: https://halt.software/dead-simple-layouts)
bool BeginViewportSideBar(string name, ImGuiViewport* viewport_p, ImGuiDir dir, float axis_size, ImGuiWindowFlags window_flags)
{
    IM_ASSERT(dir != ImGuiDir.None);

    ImGuiWindow* bar_window = FindWindowByName(name);
    if (bar_window == NULL || bar_window.BeginCount == 0)
    {
        // Calculate and set window size/position
        ImGuiViewportP* viewport = cast(ImGuiViewportP*)cast(void*)(viewport_p ? viewport_p : GetMainViewport());
        ImRect avail_rect = viewport.GetBuildWorkRect();
        ImGuiAxis axis = (dir == ImGuiDir.Up || dir == ImGuiDir.Down) ? ImGuiAxis.Y : ImGuiAxis.X;
        ImVec2 pos = avail_rect.Min;
        if (dir == ImGuiDir.Right || dir == ImGuiDir.Down)
            pos[axis] = avail_rect.Max[axis] - axis_size;
        ImVec2 size = avail_rect.GetSize();
        size[axis] = axis_size;
        SetNextWindowPos(pos);
        SetNextWindowSize(size);

        // Report our size into work area (for next frame) using actual window size
        if (dir == ImGuiDir.Up || dir == ImGuiDir.Left)
            viewport.BuildWorkOffsetMin[axis] += axis_size;
        else if (dir == ImGuiDir.Down || dir == ImGuiDir.Right)
            viewport.BuildWorkOffsetMax[axis] -= axis_size;
    }

    window_flags |= ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.NoResize | ImGuiWindowFlags.NoMove;
    PushStyleVar(ImGuiStyleVar.WindowRounding, 0.0f);
    PushStyleVar(ImGuiStyleVar.WindowMinSize, ImVec2(0, 0)); // Lift normal size constraint
    bool is_open = Begin(name, NULL, window_flags);
    PopStyleVar(2);

    return is_open;
}

bool BeginMainMenuBar()
{
    ImGuiContext* g = GImGui;
    ImGuiViewportP* viewport = cast(ImGuiViewportP*)cast(void*)GetMainViewport();

    // For the main menu bar, which cannot be moved, we honor g.Style.DisplaySafeAreaPadding to ensure text can be visible on a TV set.
    // FIXME: This could be generalized as an opt-in way to clamp window->DC.CursorStartPos to avoid SafeArea?
    // FIXME: Consider removing support for safe area down the line... it's messy. Nowadays consoles have support for TV calibration in OS settings.
    g.NextWindowData.MenuBarOffsetMinVal = ImVec2(g.Style.DisplaySafeAreaPadding.x, ImMax(g.Style.DisplaySafeAreaPadding.y - g.Style.FramePadding.y, 0.0f));
    ImGuiWindowFlags window_flags = ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoSavedSettings | ImGuiWindowFlags.MenuBar;
    float height = GetFrameHeight();
    bool is_open = BeginViewportSideBar("##MainMenuBar", &viewport.base, ImGuiDir.Up, height, window_flags);
    g.NextWindowData.MenuBarOffsetMinVal = ImVec2(0.0f, 0.0f);

    if (is_open)
        BeginMenuBar();
    else
        End();
    return is_open;
}

void EndMainMenuBar()
{
    EndMenuBar();

    // When the user has left the menu layer (typically: closed menus through activation of an item), we restore focus to the previous window
    // FIXME: With this strategy we won't be able to restore a NULL focus.
    ImGuiContext* g = GImGui;
    if (g.CurrentWindow == g.NavWindow && g.NavLayer == ImGuiNavLayer.Main && !g.NavAnyRequest)
        FocusTopMostWindowUnderOne(g.NavWindow, NULL);

    End();
}

bool BeginMenu(string label, bool enabled = true)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    ImGuiContext* g = GImGui;
    const ImGuiStyle* style = &g.Style;
    const ImGuiID id = window.GetID(label);
    bool menu_is_open = IsPopupOpen(id, ImGuiPopupFlags.None);

    // Sub-menus are ChildWindow so that mouse can be hovering across them (otherwise top-most popup menu would steal focus and not allow hovering on parent menu)
    ImGuiWindowFlags flags = ImGuiWindowFlags.ChildMenu | ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.NoSavedSettings | ImGuiWindowFlags.NoNavFocus;
    if (window.Flags & (ImGuiWindowFlags.Popup | ImGuiWindowFlags.ChildMenu))
        flags |= ImGuiWindowFlags.ChildWindow;

    // If a menu with same the ID was already submitted, we will append to it, matching the behavior of Begin().
    // We are relying on a O(N) search - so O(N log N) over the frame - which seems like the most efficient for the expected small amount of BeginMenu() calls per frame.
    // If somehow this is ever becoming a problem we can switch to use e.g. ImGuiStorage mapping key to last frame used.
    if (g.MenusIdSubmittedThisFrame.contains(id))
    {
        if (menu_is_open)
            menu_is_open = BeginPopupEx(id, flags); // menu_is_open can be 'false' when the popup is completely clipped (e.g. zero size display)
        else
            g.NextWindowData.ClearFlags();          // we behave like Begin() and need to consume those values
        return menu_is_open;
    }

    // Tag menu as used. Next time BeginMenu() with same ID is called it will append to existing menu
    g.MenusIdSubmittedThisFrame.push_back(id);

    ImVec2 label_size = CalcTextSize(label, true);
    bool pressed;
    bool menuset_is_open = !(window.Flags & ImGuiWindowFlags.Popup) && (g.OpenPopupStack.Size > g.BeginPopupStack.Size && g.OpenPopupStack[g.BeginPopupStack.Size].OpenParentId == window.IDStack.back());
    ImGuiWindow* backed_nav_window = g.NavWindow;
    if (menuset_is_open)
        g.NavWindow = window;  // Odd hack to allow hovering across menus of a same menu-set (otherwise we wouldn't be able to hover parent)

    // The reference position stored in popup_pos will be used by Begin() to find a suitable position for the child menu,
    // However the final position is going to be different! It is chosen by FindBestWindowPosForPopup().
    // e.g. Menus tend to overlap each other horizontally to amplify relative Z-ordering.
    ImVec2 popup_pos, pos = window.DC.CursorPos;
    PushID(label);
    if (!enabled)
        BeginDisabled();
    const ImGuiMenuColumns* offsets = &window.DC.MenuColumns;
    if (window.DC.LayoutType == ImGuiLayoutType.Horizontal)
    {
        // Menu inside an horizontal menu bar
        // Selectable extend their highlight by half ItemSpacing in each direction.
        // For ChildMenu, the popup position will be overwritten by the call to FindBestWindowPosForPopup() in Begin()
        popup_pos = ImVec2(pos.x - 1.0f - IM_FLOOR(style.ItemSpacing.x * 0.5f), pos.y - style.FramePadding.y + window.MenuBarHeight());
        window.DC.CursorPos.x += IM_FLOOR(style.ItemSpacing.x * 0.5f);
        PushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(style.ItemSpacing.x * 2.0f, style.ItemSpacing.y));
        float w = label_size.x;
        ImVec2 text_pos = ImVec2(window.DC.CursorPos.x + offsets.OffsetLabel, window.DC.CursorPos.y + window.DC.CurrLineTextBaseOffset);
        pressed = Selectable("", menu_is_open, ImGuiSelectableFlags.NoHoldingActiveID | ImGuiSelectableFlags.SelectOnClick | ImGuiSelectableFlags.DontClosePopups, ImVec2(w, 0.0f));
        RenderText(text_pos, label);
        PopStyleVar();
        window.DC.CursorPos.x += IM_FLOOR(style.ItemSpacing.x * (-1.0f + 0.5f)); // -1 spacing to compensate the spacing added when Selectable() did a SameLine(). It would also work to call SameLine() ourselves after the PopStyleVar().
    }
    else
    {
        // Menu inside a menu
        // (In a typical menu window where all items are BeginMenu() or MenuItem() calls, extra_w will always be 0.0f.
        //  Only when they are other items sticking out we're going to add spacing, yet only register minimum width into the layout system.
        popup_pos = ImVec2(pos.x, pos.y - style.WindowPadding.y);
        float icon_w = 0.0f; // FIXME: This not currently exposed for BeginMenu() however you can call window->DC.MenuColumns.DeclColumns(w, 0, 0, 0) yourself
        float checkmark_w = IM_FLOOR(g.FontSize * 1.20f);
        float min_w = window.DC.MenuColumns.DeclColumns(icon_w, label_size.x, 0.0f, checkmark_w); // Feedback to next frame
        float extra_w = ImMax(0.0f, GetContentRegionAvail().x - min_w);
        ImVec2 text_pos = ImVec2(window.DC.CursorPos.x + offsets.OffsetLabel, window.DC.CursorPos.y + window.DC.CurrLineTextBaseOffset);
        pressed = Selectable("", menu_is_open, ImGuiSelectableFlags.NoHoldingActiveID | ImGuiSelectableFlags.SelectOnClick | ImGuiSelectableFlags.DontClosePopups | ImGuiSelectableFlags.SpanAvailWidth, ImVec2(min_w, 0.0f));
        RenderText(text_pos, label);
        RenderArrow(window.DrawList, pos + ImVec2(offsets.OffsetMark + extra_w + g.FontSize * 0.30f, 0.0f), GetColorU32(ImGuiCol.Text), ImGuiDir.Right);
    }
    if (!enabled)
        EndDisabled();

    const bool hovered = (g.HoveredId == id) && enabled;
    if (menuset_is_open)
        g.NavWindow = backed_nav_window;

    bool want_open = false;
    bool want_close = false;
    if (window.DC.LayoutType == ImGuiLayoutType.Vertical) // (window->Flags & (ImGuiWindowFlags_Popup|ImGuiWindowFlags_ChildMenu))
    {
        // Close menu when not hovering it anymore unless we are moving roughly in the direction of the menu
        // Implement http://bjk5.com/post/44698559168/breaking-down-amazons-mega-dropdown to avoid using timers, so menus feels more reactive.
        bool moving_toward_other_child_menu = false;

        ImGuiWindow* child_menu_window = (g.BeginPopupStack.Size < g.OpenPopupStack.Size && g.OpenPopupStack[g.BeginPopupStack.Size].SourceWindow == window) ? g.OpenPopupStack[g.BeginPopupStack.Size].Window : NULL;
        if (g.HoveredWindow == window && child_menu_window != NULL && !(window.Flags & ImGuiWindowFlags.MenuBar))
        {
            // FIXME-DPI: Values should be derived from a master "scale" factor.
            ImRect next_window_rect = child_menu_window.Rect();
            ImVec2 ta = g.IO.MousePos - g.IO.MouseDelta;
            ImVec2 tb = (window.Pos.x < child_menu_window.Pos.x) ? next_window_rect.GetTL() : next_window_rect.GetTR();
            ImVec2 tc = (window.Pos.x < child_menu_window.Pos.x) ? next_window_rect.GetBL() : next_window_rect.GetBR();
            float extra = ImClamp(ImFabs(ta.x - tb.x) * 0.30f, 5.0f, 30.0f);    // add a bit of extra slack.
            ta.x += (window.Pos.x < child_menu_window.Pos.x) ? -0.5f : +0.5f; // to avoid numerical issues
            tb.y = ta.y + ImMax((tb.y - extra) - ta.y, -100.0f);                // triangle is maximum 200 high to limit the slope and the bias toward large sub-menus // FIXME: Multiply by fb_scale?
            tc.y = ta.y + ImMin((tc.y + extra) - ta.y, +100.0f);
            moving_toward_other_child_menu = ImTriangleContainsPoint(ta, tb, tc, g.IO.MousePos);
            //GetForegroundDrawList()->AddTriangleFilled(ta, tb, tc, moving_within_opened_triangle ? IM_COL32(0,128,0,128) : IM_COL32(128,0,0,128)); // [DEBUG]
        }

        // FIXME: Hovering a disabled BeginMenu or MenuItem won't close us
        if (menu_is_open && !hovered && g.HoveredWindow == window && g.HoveredIdPreviousFrame != 0 && g.HoveredIdPreviousFrame != id && !moving_toward_other_child_menu)
            want_close = true;

        if (!menu_is_open && hovered && pressed) // Click to open
            want_open = true;
        else if (!menu_is_open && hovered && !moving_toward_other_child_menu) // Hover to open
            want_open = true;

        if (g.NavActivateId == id)
        {
            want_close = menu_is_open;
            want_open = !menu_is_open;
        }
        if (g.NavId == id && g.NavMoveRequest && g.NavMoveDir == ImGuiDir.Right) // Nav-Right to open
        {
            want_open = true;
            NavMoveRequestCancel();
        }
    }
    else
    {
        // Menu bar
        if (menu_is_open && pressed && menuset_is_open) // Click an open menu again to close it
        {
            want_close = true;
            want_open = menu_is_open = false;
        }
        else if (pressed || (hovered && menuset_is_open && !menu_is_open)) // First click to open, then hover to open others
        {
            want_open = true;
        }
        else if (g.NavId == id && g.NavMoveRequest && g.NavMoveDir == ImGuiDir.Down) // Nav-Down to open
        {
            want_open = true;
            NavMoveRequestCancel();
        }
    }

    if (!enabled) // explicitly close if an open menu becomes disabled, facilitate users code a lot in pattern such as 'if (BeginMenu("options", has_object)) { ..use object.. }'
        want_close = true;
    if (want_close && IsPopupOpen(id, ImGuiPopupFlags.None))
        ClosePopupToLevel(g.BeginPopupStack.Size, true);

    IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags | ImGuiItemStatusFlags.Openable | (menu_is_open ? ImGuiItemStatusFlags.Opened : ImGuiItemStatusFlags.None));
    PopID();

    if (!menu_is_open && want_open && g.OpenPopupStack.Size > g.BeginPopupStack.Size)
    {
        // Don't recycle same menu level in the same frame, first close the other menu and yield for a frame.
        OpenPopup(label);
        return false;
    }

    menu_is_open |= want_open;
    if (want_open)
        OpenPopup(label);

    if (menu_is_open)
    {
        SetNextWindowPos(popup_pos, ImGuiCond.Always); // Note: this is super misleading! The value will serve as reference for FindBestWindowPosForPopup(), not actual pos.
        menu_is_open = BeginPopupEx(id, flags); // menu_is_open can be 'false' when the popup is completely clipped (e.g. zero size display)
    }
    else
    {
        g.NextWindowData.ClearFlags(); // We behave like Begin() and need to consume those values
    }

    return menu_is_open;
}

void EndMenu()
{
    // Nav: When a left move request _within our child menu_ failed, close ourselves (the _parent_ menu).
    // A menu doesn't close itself because EndMenuBar() wants the catch the last Left<>Right inputs.
    // However, it means that with the current code, a BeginMenu() from outside another menu or a menu-bar won't be closable with the Left direction.
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;
    if (g.NavWindow && g.NavWindow.ParentWindow == window && g.NavMoveDir == ImGuiDir.Left && NavMoveRequestButNoResultYet() && window.DC.LayoutType == ImGuiLayoutType.Vertical)
    {
        ClosePopupToLevel(g.BeginPopupStack.Size, true);
        NavMoveRequestCancel();
    }

    EndPopup();
}

bool MenuItemEx(string label, string icon, string shortcut = NULL, bool selected = false, bool enabled = true)
{
    ImGuiWindow* window = GetCurrentWindow();
    if (window.SkipItems)
        return false;

    ImGuiContext* g = GImGui;
    ImGuiStyle* style = &g.Style;
    ImVec2 pos = window.DC.CursorPos;
    ImVec2 label_size = CalcTextSize(label, true);

    // We've been using the equivalent of ImGuiSelectableFlags_SetNavIdOnHover on all Selectable() since early Nav system days (commit 43ee5d73),
    // but I am unsure whether this should be kept at all. For now moved it to be an opt-in feature used by menus only.
    bool pressed;
    PushID(label);
    if (!enabled)
        BeginDisabled(true);
    const ImGuiSelectableFlags flags = ImGuiSelectableFlags.SelectOnRelease | ImGuiSelectableFlags.SetNavIdOnHover;
    const ImGuiMenuColumns* offsets = &window.DC.MenuColumns;
    if (window.DC.LayoutType == ImGuiLayoutType.Horizontal)
    {
        // Mimic the exact layout spacing of BeginMenu() to allow MenuItem() inside a menu bar, which is a little misleading but may be useful
        // Note that in this situation: we don't render the shortcut, we render a highlight instead of the selected tick mark.
        float w = label_size.x;
        window.DC.CursorPos.x += IM_FLOOR(style.ItemSpacing.x * 0.5f);
        PushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(style.ItemSpacing.x * 2.0f, style.ItemSpacing.y));
        pressed = Selectable("", selected, flags, ImVec2(w, 0.0f));
        PopStyleVar();
        RenderText(pos + ImVec2(offsets.OffsetLabel, 0.0f), label);
        window.DC.CursorPos.x += IM_FLOOR(style.ItemSpacing.x * (-1.0f + 0.5f)); // -1 spacing to compensate the spacing added when Selectable() did a SameLine(). It would also work to call SameLine() ourselves after the PopStyleVar().
    }
    else
    {
        // Menu item inside a vertical menu
        // (In a typical menu window where all items are BeginMenu() or MenuItem() calls, extra_w will always be 0.0f.
        //  Only when they are other items sticking out we're going to add spacing, yet only register minimum width into the layout system.
        float icon_w = (icon && icon[0]) ? CalcTextSize(icon).x : 0.0f;
        float shortcut_w = (shortcut && shortcut[0]) ? CalcTextSize(shortcut).x : 0.0f;
        float checkmark_w = IM_FLOOR(g.FontSize * 1.20f);
        float min_w = window.DC.MenuColumns.DeclColumns(icon_w, label_size.x, shortcut_w, checkmark_w); // Feedback for next frame
        float stretch_w = ImMax(0.0f, GetContentRegionAvail().x - min_w);
        pressed = Selectable("", false, flags | ImGuiSelectableFlags.SpanAvailWidth, ImVec2(min_w, 0.0f));
        RenderText(pos + ImVec2(offsets.OffsetLabel, 0.0f), label);
        if (icon_w > 0.0f)
            RenderText(pos + ImVec2(offsets.OffsetIcon, 0.0f), icon);
        if (shortcut_w > 0.0f)
        {
            PushStyleColor(ImGuiCol.Text, style.Colors[ImGuiCol.TextDisabled]);
            RenderText(pos + ImVec2(offsets.OffsetShortcut + stretch_w, 0.0f), shortcut, false);
            PopStyleColor();
        }
        if (selected)
            RenderCheckMark(window.DrawList, pos + ImVec2(offsets.OffsetMark + stretch_w + g.FontSize * 0.40f, g.FontSize * 0.134f * 0.5f), GetColorU32(ImGuiCol.Text), g.FontSize  * 0.866f);
    }
    IMGUI_TEST_ENGINE_ITEM_INFO(g.LastItemData.ID, label, g.LastItemData.StatusFlags | ImGuiItemStatusFlags.Checkable | (selected ? ImGuiItemStatusFlags.Checked : ImGuiItemStatusFlags.None));
    if (!enabled)
        EndDisabled();
    PopID();

    return pressed;
}

bool MenuItem(string label, string shortcut = NULL, bool selected = false, bool enabled = true)
{
    return MenuItemEx(label, NULL, shortcut, selected, enabled);
}

bool MenuItem(string label, string shortcut, bool* p_selected, bool enabled = true)
{
    if (MenuItemEx(label, NULL, shortcut, p_selected ? *p_selected : false, enabled))
    {
        if (p_selected)
            *p_selected = !*p_selected;
        return true;
    }
    return false;
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: BeginTabBar, EndTabBar, etc.
//-------------------------------------------------------------------------
// - BeginTabBar()
// - BeginTabBarEx() [Internal]
// - EndTabBar()
// - TabBarLayout() [Internal]
// - TabBarCalcTabID() [Internal]
// - TabBarCalcMaxTabWidth() [Internal]
// - TabBarFindTabById() [Internal]
// - TabBarRemoveTab() [Internal]
// - TabBarCloseTab() [Internal]
// - TabBarScrollClamp() [Internal]
// - TabBarScrollToTab() [Internal]
// - TabBarQueueChangeTabOrder() [Internal]
// - TabBarScrollingButtons() [Internal]
// - TabBarTabListPopupButton() [Internal]
//-------------------------------------------------------------------------

struct ImGuiTabBarSection
{
    nothrow:
    @nogc:

    int                 TabCount;               // Number of tabs in this section.
    float               Width;                  // Sum of width of tabs in this section (after shrinking down)
    float               Spacing;                // Horizontal spacing at the end of the section.

    @disable this();
    this(bool dummy) { memset(&this, 0, sizeof(this)); }
}

/+
namespace ImGui
{
    static void             TabBarLayout(ImGuiTabBar* tab_bar);
    static ImU32            TabBarCalcTabID(ImGuiTabBar* tab_bar, string label);
    static float            TabBarCalcMaxTabWidth();
    static float            TabBarScrollClamp(ImGuiTabBar* tab_bar, float scrolling);
    static void             TabBarScrollToTab(ImGuiTabBar* tab_bar, ImGuiID tab_id, ImGuiTabBarSection* sections);
    static ImGuiTabItem*    TabBarScrollingButtons(ImGuiTabBar* tab_bar);
    static ImGuiTabItem*    TabBarTabListPopupButton(ImGuiTabBar* tab_bar);
}
+/

// D_IMGUI: Wrapper for ImGuiTabBar
struct ImGuiTabBar_Wrapper {

    nothrow:
    @nogc:

    ImGuiTabBar _data = ImGuiTabBar.init;
    alias _data this;

this(bool dummy)
{
    memset(&this, 0, sizeof(this));
    CurrFrameVisible = PrevFrameVisible = -1;
    LastTabItemIdx = -1;
}
}

pragma(inline, true) int TabItemGetSectionIdx(const ImGuiTabItem* tab)
{
    return (tab.Flags & ImGuiTabItemFlags.Leading) ? 0 : (tab.Flags & ImGuiTabItemFlags.Trailing) ? 2 : 1;
}

int TabItemComparerBySection(const ImGuiTabItem* a, const ImGuiTabItem* b)
{
    const int a_section = TabItemGetSectionIdx(a);
    const int b_section = TabItemGetSectionIdx(b);
    if (a_section != b_section)
        return a_section - b_section;
    return cast(int)(a.IndexDuringLayout - b.IndexDuringLayout);
}

int TabItemComparerByBeginOrder(const ImGuiTabItem* a, const ImGuiTabItem* b)
{
    return cast(int)(a.BeginOrder - b.BeginOrder);
}

static ImGuiTabBar* GetTabBarFromTabBarRef(const ImGuiPtrOrIndex/*&*/ _ref)
{
    ImGuiContext* g = GImGui;
    return _ref.Ptr ? cast(ImGuiTabBar*)_ref.Ptr : g.TabBars.GetByIndex(_ref.Index);
}

ImGuiPtrOrIndex GetTabBarRefFromTabBar(ImGuiTabBar* tab_bar)
{
    ImGuiContext* g = GImGui;
    if (g.TabBars.Contains(tab_bar))
        return ImGuiPtrOrIndex(g.TabBars.GetIndex(tab_bar));
    return ImGuiPtrOrIndex(tab_bar);
}

bool    BeginTabBar(string str_id, ImGuiTabBarFlags flags = ImGuiTabBarFlags.None)
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;
    if (window.SkipItems)
        return false;

    ImGuiID id = window.GetID(str_id);
    ImGuiTabBar* tab_bar = g.TabBars.GetOrAddByKey(id);
    ImRect tab_bar_bb = ImRect(window.DC.CursorPos.x, window.DC.CursorPos.y, window.WorkRect.Max.x, window.DC.CursorPos.y + g.FontSize + g.Style.FramePadding.y * 2);
    tab_bar.ID = id;
    return BeginTabBarEx(tab_bar, tab_bar_bb, flags | ImGuiTabBarFlags.IsFocused);
}

bool    BeginTabBarEx(ImGuiTabBar* tab_bar, const ImRect/*&*/ tab_bar_bb, ImGuiTabBarFlags flags)
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;
    if (window.SkipItems)
        return false;

    if ((flags & ImGuiTabBarFlags.DockNode) == 0)
        PushOverrideID(tab_bar.ID);

    // Add to stack
    g.CurrentTabBarStack.push_back(GetTabBarRefFromTabBar(tab_bar));
    g.CurrentTabBar = tab_bar;

    // Append with multiple BeginTabBar()/EndTabBar() pairs.
    tab_bar.BackupCursorPos = window.DC.CursorPos;
    if (tab_bar.CurrFrameVisible == g.FrameCount)
    {
        window.DC.CursorPos = ImVec2(tab_bar.BarRect.Min.x, tab_bar.BarRect.Max.y + tab_bar.ItemSpacingY);
        tab_bar.BeginCount++;
        return true;
    }

    // Ensure correct ordering when toggling ImGuiTabBarFlags_Reorderable flag, or when a new tab was added while being not reorderable
    if ((flags & ImGuiTabBarFlags.Reorderable) != (tab_bar.Flags & ImGuiTabBarFlags.Reorderable) || (tab_bar.TabsAddedNew && !(flags & ImGuiTabBarFlags.Reorderable)))
        if (tab_bar.Tabs.Size > 1)
            ImQsort(tab_bar.Tabs.asArray(), &TabItemComparerByBeginOrder);
    tab_bar.TabsAddedNew = false;

    // Flags
    if ((flags & ImGuiTabBarFlags.FittingPolicyMask_) == 0)
        flags |= ImGuiTabBarFlags.FittingPolicyDefault_;

    tab_bar.Flags = flags;
    tab_bar.BarRect = tab_bar_bb;
    tab_bar.WantLayout = true; // Layout will be done on the first call to ItemTab()
    tab_bar.PrevFrameVisible = tab_bar.CurrFrameVisible;
    tab_bar.CurrFrameVisible = g.FrameCount;
    tab_bar.PrevTabsContentsHeight = tab_bar.CurrTabsContentsHeight;
    tab_bar.CurrTabsContentsHeight = 0.0f;
    tab_bar.ItemSpacingY = g.Style.ItemSpacing.y;
    tab_bar.FramePadding = g.Style.FramePadding;
    tab_bar.TabsActiveCount = 0;
    tab_bar.BeginCount = 1;

    // Set cursor pos in a way which only be used in the off-chance the user erroneously submits item before BeginTabItem(): items will overlap
    window.DC.CursorPos = ImVec2(tab_bar.BarRect.Min.x, tab_bar.BarRect.Max.y + tab_bar.ItemSpacingY);

    // Draw separator
    const ImU32 col = GetColorU32((flags & ImGuiTabBarFlags.IsFocused) ? ImGuiCol.TabActive : ImGuiCol.TabUnfocusedActive);
    const float y = tab_bar.BarRect.Max.y - 1.0f;
    {
        const float separator_min_x = tab_bar.BarRect.Min.x - IM_FLOOR(window.WindowPadding.x * 0.5f);
        const float separator_max_x = tab_bar.BarRect.Max.x + IM_FLOOR(window.WindowPadding.x * 0.5f);
        window.DrawList.AddLine(ImVec2(separator_min_x, y), ImVec2(separator_max_x, y), col, 1.0f);
    }
    return true;
}

void    EndTabBar()
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;
    if (window.SkipItems)
        return;

    ImGuiTabBar* tab_bar = g.CurrentTabBar;
    if (tab_bar == NULL)
    {
        IM_ASSERT_USER_ERROR(tab_bar != NULL, "Mismatched BeginTabBar()/EndTabBar()!");
        return;
    }

    // Fallback in case no TabItem have been submitted
    if (tab_bar.WantLayout)
        TabBarLayout(tab_bar);

    // Restore the last visible height if no tab is visible, this reduce vertical flicker/movement when a tabs gets removed without calling SetTabItemClosed().
    const bool tab_bar_appearing = (tab_bar.PrevFrameVisible + 1 < g.FrameCount);
    if (tab_bar.VisibleTabWasSubmitted || tab_bar.VisibleTabId == 0 || tab_bar_appearing)
    {
        tab_bar.CurrTabsContentsHeight = ImMax(window.DC.CursorPos.y - tab_bar.BarRect.Max.y, tab_bar.CurrTabsContentsHeight);
        window.DC.CursorPos.y = tab_bar.BarRect.Max.y + tab_bar.CurrTabsContentsHeight;
    }
    else
    {
        window.DC.CursorPos.y = tab_bar.BarRect.Max.y + tab_bar.PrevTabsContentsHeight;
    }
    if (tab_bar.BeginCount > 1)
        window.DC.CursorPos = tab_bar.BackupCursorPos;

    if ((tab_bar.Flags & ImGuiTabBarFlags.DockNode) == 0)
        PopID();

    g.CurrentTabBarStack.pop_back();
    g.CurrentTabBar = g.CurrentTabBarStack.empty() ? NULL : GetTabBarFromTabBarRef(g.CurrentTabBarStack.back());
}

// This is called only once a frame before by the first call to ItemTab()
// The reason we're not calling it in BeginTabBar() is to leave a chance to the user to call the SetTabItemClosed() functions.
void TabBarLayout(ImGuiTabBar* tab_bar)
{
    ImGuiContext* g = GImGui;
    tab_bar.WantLayout = false;

    // Garbage collect by compacting list
    // Detect if we need to sort out tab list (e.g. in rare case where a tab changed section)
    int tab_dst_n = 0;
    bool need_sort_by_section = false;
    ImGuiTabBarSection[3] sections = ImGuiTabBarSection(false); // Layout sections: Leading, Central, Trailing
    for (int tab_src_n = 0; tab_src_n < tab_bar.Tabs.Size; tab_src_n++)
    {
        ImGuiTabItem* tab = &tab_bar.Tabs[tab_src_n];
        if (tab.LastFrameVisible < tab_bar.PrevFrameVisible || tab.WantClose)
        {
            // Remove tab
            if (tab_bar.VisibleTabId == tab.ID) { tab_bar.VisibleTabId = 0; }
            if (tab_bar.SelectedTabId == tab.ID) { tab_bar.SelectedTabId = 0; }
            if (tab_bar.NextSelectedTabId == tab.ID) { tab_bar.NextSelectedTabId = 0; }
            continue;
        }
        if (tab_dst_n != tab_src_n)
            tab_bar.Tabs[tab_dst_n] = tab_bar.Tabs[tab_src_n];

        tab = &tab_bar.Tabs[tab_dst_n];
        tab.IndexDuringLayout = cast(ImS16)tab_dst_n;

        // We will need sorting if tabs have changed section (e.g. moved from one of Leading/Central/Trailing to another)
        int curr_tab_section_n = TabItemGetSectionIdx(tab);
        if (tab_dst_n > 0)
        {
            ImGuiTabItem* prev_tab = &tab_bar.Tabs[tab_dst_n - 1];
            int prev_tab_section_n = TabItemGetSectionIdx(prev_tab);
            if (curr_tab_section_n == 0 && prev_tab_section_n != 0)
                need_sort_by_section = true;
            if (prev_tab_section_n == 2 && curr_tab_section_n != 2)
                need_sort_by_section = true;
        }

        sections[curr_tab_section_n].TabCount++;
        tab_dst_n++;
    }
    if (tab_bar.Tabs.Size != tab_dst_n)
        tab_bar.Tabs.resize(tab_dst_n);

    if (need_sort_by_section)
        ImQsort(tab_bar.Tabs.asArray(), &TabItemComparerBySection);

    // Calculate spacing between sections
    sections[0].Spacing = sections[0].TabCount > 0 && (sections[1].TabCount + sections[2].TabCount) > 0 ? g.Style.ItemInnerSpacing.x : 0.0f;
    sections[1].Spacing = sections[1].TabCount > 0 && sections[2].TabCount > 0 ? g.Style.ItemInnerSpacing.x : 0.0f;

    // Setup next selected tab
    ImGuiID scroll_to_tab_id = 0;
    if (tab_bar.NextSelectedTabId)
    {
        tab_bar.SelectedTabId = tab_bar.NextSelectedTabId;
        tab_bar.NextSelectedTabId = 0;
        scroll_to_tab_id = tab_bar.SelectedTabId;
    }

    // Process order change request (we could probably process it when requested but it's just saner to do it in a single spot).
    if (tab_bar.ReorderRequestTabId != 0)
    {
        if (TabBarProcessReorder(tab_bar))
            if (tab_bar.ReorderRequestTabId == tab_bar.SelectedTabId)
                scroll_to_tab_id = tab_bar.ReorderRequestTabId;
        tab_bar.ReorderRequestTabId = 0;
    }

    // Tab List Popup (will alter tab_bar->BarRect and therefore the available width!)
    const bool tab_list_popup_button = (tab_bar.Flags & ImGuiTabBarFlags.TabListPopupButton) != 0;
    if (tab_list_popup_button)
        if (ImGuiTabItem* tab_to_select = TabBarTabListPopupButton(tab_bar)) // NB: Will alter BarRect.Min.x!
            scroll_to_tab_id = tab_bar.SelectedTabId = tab_to_select.ID;

    // Leading/Trailing tabs will be shrink only if central one aren't visible anymore, so layout the shrink data as: leading, trailing, central
    // (whereas our tabs are stored as: leading, central, trailing)
    int[3] shrink_buffer_indexes = [ 0, sections[0].TabCount + sections[2].TabCount, sections[0].TabCount ];
    g.ShrinkWidthBuffer.resize(tab_bar.Tabs.Size);

    // Compute ideal tabs widths + store them into shrink buffer
    ImGuiTabItem* most_recently_selected_tab = NULL;
    int curr_section_n = -1;
    bool found_selected_tab_id = false;
    for (int tab_n = 0; tab_n < tab_bar.Tabs.Size; tab_n++)
    {
        ImGuiTabItem* tab = &tab_bar.Tabs[tab_n];
        IM_ASSERT(tab.LastFrameVisible >= tab_bar.PrevFrameVisible);

        if ((most_recently_selected_tab == NULL || most_recently_selected_tab.LastFrameSelected < tab.LastFrameSelected) && !(tab.Flags & ImGuiTabItemFlags.Button))
            most_recently_selected_tab = tab;
        if (tab.ID == tab_bar.SelectedTabId)
            found_selected_tab_id = true;
        if (scroll_to_tab_id == 0 && g.NavJustMovedToId == tab.ID)
            scroll_to_tab_id = tab.ID;

        // Refresh tab width immediately, otherwise changes of style e.g. style.FramePadding.x would noticeably lag in the tab bar.
        // Additionally, when using TabBarAddTab() to manipulate tab bar order we occasionally insert new tabs that don't have a width yet,
        // and we cannot wait for the next BeginTabItem() call. We cannot compute this width within TabBarAddTab() because font size depends on the active window.
        string tab_name = tab_bar.GetTabName(tab);
        const bool has_close_button = (tab.Flags & ImGuiTabItemFlags.NoCloseButton) ? false : true;
        tab.ContentWidth = TabItemCalcSize(tab_name, has_close_button).x;

        int section_n = TabItemGetSectionIdx(tab);
        ImGuiTabBarSection* section = &sections[section_n];
        section.Width += tab.ContentWidth + (section_n == curr_section_n ? g.Style.ItemInnerSpacing.x : 0.0f);
        curr_section_n = section_n;

        // Store data so we can build an array sorted by width if we need to shrink tabs down
        // IM_MSVC_WARNING_SUPPRESS(6385);
        int shrink_buffer_index = shrink_buffer_indexes[section_n]++;
        g.ShrinkWidthBuffer[shrink_buffer_index].Index = tab_n;
        g.ShrinkWidthBuffer[shrink_buffer_index].Width = tab.ContentWidth;

        IM_ASSERT(tab.ContentWidth > 0.0f);
        tab.Width = tab.ContentWidth;
    }

    // Compute total ideal width (used for e.g. auto-resizing a window)
    tab_bar.WidthAllTabsIdeal = 0.0f;
    for (int section_n = 0; section_n < 3; section_n++)
        tab_bar.WidthAllTabsIdeal += sections[section_n].Width + sections[section_n].Spacing;

    // Horizontal scrolling buttons
    // (note that TabBarScrollButtons() will alter BarRect.Max.x)
    if ((tab_bar.WidthAllTabsIdeal > tab_bar.BarRect.GetWidth() && tab_bar.Tabs.Size > 1) && !(tab_bar.Flags & ImGuiTabBarFlags.NoTabListScrollingButtons) && (tab_bar.Flags & ImGuiTabBarFlags.FittingPolicyScroll))
        if (ImGuiTabItem* scroll_and_select_tab = TabBarScrollingButtons(tab_bar))
        {
            scroll_to_tab_id = scroll_and_select_tab.ID;
            if ((scroll_and_select_tab.Flags & ImGuiTabItemFlags.Button) == 0)
                tab_bar.SelectedTabId = scroll_to_tab_id;
        }

    // Shrink widths if full tabs don't fit in their allocated space
    float section_0_w = sections[0].Width + sections[0].Spacing;
    float section_1_w = sections[1].Width + sections[1].Spacing;
    float section_2_w = sections[2].Width + sections[2].Spacing;
    bool central_section_is_visible = (section_0_w + section_2_w) < tab_bar.BarRect.GetWidth();
    float width_excess;
    if (central_section_is_visible)
        width_excess = ImMax(section_1_w - (tab_bar.BarRect.GetWidth() - section_0_w - section_2_w), 0.0f); // Excess used to shrink central section
    else
        width_excess = (section_0_w + section_2_w) - tab_bar.BarRect.GetWidth(); // Excess used to shrink leading/trailing section

    // With ImGuiTabBarFlags_FittingPolicyScroll policy, we will only shrink leading/trailing if the central section is not visible anymore
    if (width_excess > 0.0f && ((tab_bar.Flags & ImGuiTabBarFlags.FittingPolicyResizeDown) || !central_section_is_visible))
    {
        int shrink_data_count = (central_section_is_visible ? sections[1].TabCount : sections[0].TabCount + sections[2].TabCount);
        int shrink_data_offset = (central_section_is_visible ? sections[0].TabCount + sections[2].TabCount : 0);
        ShrinkWidths(g.ShrinkWidthBuffer.Data + shrink_data_offset, shrink_data_count, width_excess);

        // Apply shrunk values into tabs and sections
        for (int tab_n = shrink_data_offset; tab_n < shrink_data_offset + shrink_data_count; tab_n++)
        {
            ImGuiTabItem* tab = &tab_bar.Tabs[g.ShrinkWidthBuffer[tab_n].Index];
            float shrinked_width = IM_FLOOR(g.ShrinkWidthBuffer[tab_n].Width);
            if (shrinked_width < 0.0f)
                continue;

            int section_n = TabItemGetSectionIdx(tab);
            sections[section_n].Width -= (tab.Width - shrinked_width);
            tab.Width = shrinked_width;
        }
    }

    // Layout all active tabs
    int section_tab_index = 0;
    float tab_offset = 0.0f;
    tab_bar.WidthAllTabs = 0.0f;
    for (int section_n = 0; section_n < 3; section_n++)
    {
        ImGuiTabBarSection* section = &sections[section_n];
        if (section_n == 2)
            tab_offset = ImMin(ImMax(0.0f, tab_bar.BarRect.GetWidth() - section.Width), tab_offset);

        for (int tab_n = 0; tab_n < section.TabCount; tab_n++)
        {
            ImGuiTabItem* tab = &tab_bar.Tabs[section_tab_index + tab_n];
            tab.Offset = tab_offset;
            tab_offset += tab.Width + (tab_n < section.TabCount - 1 ? g.Style.ItemInnerSpacing.x : 0.0f);
        }
        tab_bar.WidthAllTabs += ImMax(section.Width + section.Spacing, 0.0f);
        tab_offset += section.Spacing;
        section_tab_index += section.TabCount;
    }

    // If we have lost the selected tab, select the next most recently active one
    if (found_selected_tab_id == false)
        tab_bar.SelectedTabId = 0;
    if (tab_bar.SelectedTabId == 0 && tab_bar.NextSelectedTabId == 0 && most_recently_selected_tab != NULL)
        scroll_to_tab_id = tab_bar.SelectedTabId = most_recently_selected_tab.ID;

    // Lock in visible tab
    tab_bar.VisibleTabId = tab_bar.SelectedTabId;
    tab_bar.VisibleTabWasSubmitted = false;

    // Update scrolling
    if (scroll_to_tab_id != 0)
        TabBarScrollToTab(tab_bar, scroll_to_tab_id, sections.ptr);
    tab_bar.ScrollingAnim = TabBarScrollClamp(tab_bar, tab_bar.ScrollingAnim);
    tab_bar.ScrollingTarget = TabBarScrollClamp(tab_bar, tab_bar.ScrollingTarget);
    if (tab_bar.ScrollingAnim != tab_bar.ScrollingTarget)
    {
        // Scrolling speed adjust itself so we can always reach our target in 1/3 seconds.
        // Teleport if we are aiming far off the visible line
        tab_bar.ScrollingSpeed = ImMax(tab_bar.ScrollingSpeed, 70.0f * g.FontSize);
        tab_bar.ScrollingSpeed = ImMax(tab_bar.ScrollingSpeed, ImFabs(tab_bar.ScrollingTarget - tab_bar.ScrollingAnim) / 0.3f);
        const bool teleport = (tab_bar.PrevFrameVisible + 1 < g.FrameCount) || (tab_bar.ScrollingTargetDistToVisibility > 10.0f * g.FontSize);
        tab_bar.ScrollingAnim = teleport ? tab_bar.ScrollingTarget : ImLinearSweep(tab_bar.ScrollingAnim, tab_bar.ScrollingTarget, g.IO.DeltaTime * tab_bar.ScrollingSpeed);
    }
    else
    {
        tab_bar.ScrollingSpeed = 0.0f;
    }
    tab_bar.ScrollingRectMinX = tab_bar.BarRect.Min.x + sections[0].Width + sections[0].Spacing;
    tab_bar.ScrollingRectMaxX = tab_bar.BarRect.Max.x - sections[2].Width - sections[1].Spacing;

    // Clear name buffers
    if ((tab_bar.Flags & ImGuiTabBarFlags.DockNode) == 0)
        tab_bar.TabsNames.Buf.resize(0);

    // Actual layout in host window (we don't do it in BeginTabBar() so as not to waste an extra frame)
    ImGuiWindow* window = g.CurrentWindow;
    window.DC.CursorPos = tab_bar.BarRect.Min;
    ItemSize(ImVec2(tab_bar.WidthAllTabs, tab_bar.BarRect.GetHeight()), tab_bar.FramePadding.y);
    window.DC.IdealMaxPos.x = ImMax(window.DC.IdealMaxPos.x, tab_bar.BarRect.Min.x + tab_bar.WidthAllTabsIdeal);
}

// Dockables uses Name/ID in the global namespace. Non-dockable items use the ID stack.
ImU32   TabBarCalcTabID(ImGuiTabBar* tab_bar, string label)
{
    if (tab_bar.Flags & ImGuiTabBarFlags.DockNode)
    {
        ImGuiID id = ImHashStr(label);
        KeepAliveID(id);
        return id;
    }
    else
    {
        ImGuiWindow* window = GImGui.CurrentWindow;
        return window.GetID(label);
    }
}

float TabBarCalcMaxTabWidth()
{
    ImGuiContext* g = GImGui;
    return g.FontSize * 20.0f;
}

ImGuiTabItem* TabBarFindTabByID(ImGuiTabBar* tab_bar, ImGuiID tab_id)
{
    if (tab_id != 0)
        for (int n = 0; n < tab_bar.Tabs.Size; n++)
            if (tab_bar.Tabs[n].ID == tab_id)
                return &tab_bar.Tabs[n];
    return NULL;
}

// The *TabId fields be already set by the docking system _before_ the actual TabItem was created, so we clear them regardless.
void TabBarRemoveTab(ImGuiTabBar* tab_bar, ImGuiID tab_id)
{
    if (ImGuiTabItem* tab = TabBarFindTabByID(tab_bar, tab_id))
        tab_bar.Tabs.erase(tab);
    if (tab_bar.VisibleTabId == tab_id)      { tab_bar.VisibleTabId = 0; }
    if (tab_bar.SelectedTabId == tab_id)     { tab_bar.SelectedTabId = 0; }
    if (tab_bar.NextSelectedTabId == tab_id) { tab_bar.NextSelectedTabId = 0; }
}

// Called on manual closure attempt
void TabBarCloseTab(ImGuiTabBar* tab_bar, ImGuiTabItem* tab)
{
    IM_ASSERT(!(tab.Flags & ImGuiTabItemFlags.Button));
    if (!(tab.Flags & ImGuiTabItemFlags.UnsavedDocument))
    {
        // This will remove a frame of lag for selecting another tab on closure.
        // However we don't run it in the case where the 'Unsaved' flag is set, so user gets a chance to fully undo the closure
        tab.WantClose = true;
        if (tab_bar.VisibleTabId == tab.ID)
        {
            tab.LastFrameVisible = -1;
            tab_bar.SelectedTabId = tab_bar.NextSelectedTabId = 0;
        }
    }
    else
    {
        // Actually select before expecting closure attempt (on an UnsavedDocument tab user is expect to e.g. show a popup)
        if (tab_bar.VisibleTabId != tab.ID)
            tab_bar.NextSelectedTabId = tab.ID;
    }
}

float TabBarScrollClamp(ImGuiTabBar* tab_bar, float scrolling)
{
    scrolling = ImMin(scrolling, tab_bar.WidthAllTabs - tab_bar.BarRect.GetWidth());
    return ImMax(scrolling, 0.0f);
}

// Note: we may scroll to tab that are not selected! e.g. using keyboard arrow keys
void TabBarScrollToTab(ImGuiTabBar* tab_bar, ImGuiID tab_id, ImGuiTabBarSection* sections)
{
    ImGuiTabItem* tab = TabBarFindTabByID(tab_bar, tab_id);
    if (tab == NULL)
        return;
    if (tab.Flags & ImGuiTabItemFlags.SectionMask_)
        return;

    ImGuiContext* g = GImGui;
    float margin = g.FontSize * 1.0f; // When to scroll to make Tab N+1 visible always make a bit of N visible to suggest more scrolling area (since we don't have a scrollbar)
    int order = tab_bar.GetTabOrder(tab);

    // Scrolling happens only in the central section (leading/trailing sections are not scrolling)
    // FIXME: This is all confusing.
    float scrollable_width = tab_bar.BarRect.GetWidth() - sections[0].Width - sections[2].Width - sections[1].Spacing;

    // We make all tabs positions all relative Sections[0].Width to make code simpler
    float tab_x1 = tab.Offset - sections[0].Width + (order > sections[0].TabCount - 1 ? -margin : 0.0f);
    float tab_x2 = tab.Offset - sections[0].Width + tab.Width + (order + 1 < tab_bar.Tabs.Size - sections[2].TabCount ? margin : 1.0f);
    tab_bar.ScrollingTargetDistToVisibility = 0.0f;
    if (tab_bar.ScrollingTarget > tab_x1 || (tab_x2 - tab_x1 >= scrollable_width))
    {
        // Scroll to the left
        tab_bar.ScrollingTargetDistToVisibility = ImMax(tab_bar.ScrollingAnim - tab_x2, 0.0f);
        tab_bar.ScrollingTarget = tab_x1;
    }
    else if (tab_bar.ScrollingTarget < tab_x2 - scrollable_width)
    {
        // Scroll to the right
        tab_bar.ScrollingTargetDistToVisibility = ImMax((tab_x1 - scrollable_width) - tab_bar.ScrollingAnim, 0.0f);
        tab_bar.ScrollingTarget = tab_x2 - scrollable_width;
    }
}

void TabBarQueueReorder(ImGuiTabBar* tab_bar, const ImGuiTabItem* tab, int offset)
{
    IM_ASSERT(offset != 0);
    IM_ASSERT(tab_bar.ReorderRequestTabId == 0);
    tab_bar.ReorderRequestTabId = tab.ID;
    tab_bar.ReorderRequestOffset = cast(ImS16)offset;
}

void TabBarQueueReorderFromMousePos(ImGuiTabBar* tab_bar, const ImGuiTabItem* src_tab, ImVec2 mouse_pos)
{
    ImGuiContext* g = GImGui;
    IM_ASSERT(tab_bar.ReorderRequestTabId == 0);
    if ((tab_bar.Flags & ImGuiTabBarFlags.Reorderable) == 0)
        return;

    const bool is_central_section = (src_tab.Flags & ImGuiTabItemFlags.SectionMask_) == 0;
    const float bar_offset = tab_bar.BarRect.Min.x - (is_central_section ? tab_bar.ScrollingTarget : 0);

    // Count number of contiguous tabs we are crossing over
    const int dir = (bar_offset + src_tab.Offset) > mouse_pos.x ? -1 : +1;
    const int src_idx = tab_bar.Tabs.index_from_ptr(src_tab);
    int dst_idx = src_idx;
    for (int i = src_idx; i >= 0 && i < tab_bar.Tabs.Size; i += dir)
    {
        // Reordered tabs must share the same section
        const ImGuiTabItem* dst_tab = &tab_bar.Tabs[i];
        if (dst_tab.Flags & ImGuiTabItemFlags.NoReorder)
            break;
        if ((dst_tab.Flags & ImGuiTabItemFlags.SectionMask_) != (src_tab.Flags & ImGuiTabItemFlags.SectionMask_))
            break;
        dst_idx = i;

        // Include spacing after tab, so when mouse cursor is between tabs we would not continue checking further tabs that are not hovered.
        const float x1 = bar_offset + dst_tab.Offset - g.Style.ItemInnerSpacing.x;
        const float x2 = bar_offset + dst_tab.Offset + dst_tab.Width + g.Style.ItemInnerSpacing.x;
        //GetForegroundDrawList()->AddRect(ImVec2(x1, tab_bar->BarRect.Min.y), ImVec2(x2, tab_bar->BarRect.Max.y), IM_COL32(255, 0, 0, 255));
        if ((dir < 0 && mouse_pos.x > x1) || (dir > 0 && mouse_pos.x < x2))
            break;
    }

    if (dst_idx != src_idx)
        TabBarQueueReorder(tab_bar, src_tab, dst_idx - src_idx);
}

bool TabBarProcessReorder(ImGuiTabBar* tab_bar)
{
    ImGuiTabItem* tab1 = TabBarFindTabByID(tab_bar, tab_bar.ReorderRequestTabId);
    if (tab1 == NULL || (tab1.Flags & ImGuiTabItemFlags.NoReorder))
        return false;

    //IM_ASSERT(tab_bar->Flags & ImGuiTabBarFlags_Reorderable); // <- this may happen when using debug tools
    int tab2_order = tab_bar.GetTabOrder(tab1) + tab_bar.ReorderRequestOffset;
    if (tab2_order < 0 || tab2_order >= tab_bar.Tabs.Size)
        return false;

    // Reordered tabs must share the same section
    // (Note: TabBarQueueReorderFromMousePos() also has a similar test but since we allow direct calls to TabBarQueueReorder() we do it here too)
    ImGuiTabItem* tab2 = &tab_bar.Tabs[tab2_order];
    if (tab2.Flags & ImGuiTabItemFlags.NoReorder)
        return false;
    if ((tab1.Flags & ImGuiTabItemFlags.SectionMask_) != (tab2.Flags & ImGuiTabItemFlags.SectionMask_))
        return false;

    ImGuiTabItem item_tmp = *tab1;
    ImGuiTabItem* src_tab = (tab_bar.ReorderRequestOffset > 0) ? tab1 + 1 : tab2;
    ImGuiTabItem* dst_tab = (tab_bar.ReorderRequestOffset > 0) ? tab1 : tab2 + 1;
    const int move_count = (tab_bar.ReorderRequestOffset > 0) ? tab_bar.ReorderRequestOffset : -tab_bar.ReorderRequestOffset;
    memmove(dst_tab, src_tab, move_count * sizeof!(ImGuiTabItem));
    *tab2 = item_tmp;

    if (tab_bar.Flags & ImGuiTabBarFlags.SaveSettings)
        MarkIniSettingsDirty();
    return true;
}

ImGuiTabItem* TabBarScrollingButtons(ImGuiTabBar* tab_bar)
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;

    const ImVec2 arrow_button_size = ImVec2(g.FontSize - 2.0f, g.FontSize + g.Style.FramePadding.y * 2.0f);
    const float scrolling_buttons_width = arrow_button_size.x * 2.0f;

    const ImVec2 backup_cursor_pos = window.DC.CursorPos;
    //window->DrawList->AddRect(ImVec2(tab_bar->BarRect.Max.x - scrolling_buttons_width, tab_bar->BarRect.Min.y), ImVec2(tab_bar->BarRect.Max.x, tab_bar->BarRect.Max.y), IM_COL32(255,0,0,255));

    int select_dir = 0;
    ImVec4 arrow_col = g.Style.Colors[ImGuiCol.Text];
    arrow_col.w *= 0.5f;

    PushStyleColor(ImGuiCol.Text, arrow_col);
    PushStyleColor(ImGuiCol.Button, ImVec4(0, 0, 0, 0));
    const float backup_repeat_delay = g.IO.KeyRepeatDelay;
    const float backup_repeat_rate = g.IO.KeyRepeatRate;
    g.IO.KeyRepeatDelay = 0.250f;
    g.IO.KeyRepeatRate = 0.200f;
    float x = ImMax(tab_bar.BarRect.Min.x, tab_bar.BarRect.Max.x - scrolling_buttons_width);
    window.DC.CursorPos = ImVec2(x, tab_bar.BarRect.Min.y);
    if (ArrowButtonEx("##<", ImGuiDir.Left, arrow_button_size, ImGuiButtonFlags.PressedOnClick | ImGuiButtonFlags.Repeat))
        select_dir = -1;
    window.DC.CursorPos = ImVec2(x + arrow_button_size.x, tab_bar.BarRect.Min.y);
    if (ArrowButtonEx("##>", ImGuiDir.Right, arrow_button_size, ImGuiButtonFlags.PressedOnClick | ImGuiButtonFlags.Repeat))
        select_dir = +1;
    PopStyleColor(2);
    g.IO.KeyRepeatRate = backup_repeat_rate;
    g.IO.KeyRepeatDelay = backup_repeat_delay;

    ImGuiTabItem* tab_to_scroll_to = NULL;
    if (select_dir != 0)
        if (ImGuiTabItem* tab_item = TabBarFindTabByID(tab_bar, tab_bar.SelectedTabId))
        {
            int selected_order = tab_bar.GetTabOrder(tab_item);
            int target_order = selected_order + select_dir;

            // Skip tab item buttons until another tab item is found or end is reached
            while (tab_to_scroll_to == NULL)
            {
                // If we are at the end of the list, still scroll to make our tab visible
                tab_to_scroll_to = &tab_bar.Tabs[(target_order >= 0 && target_order < tab_bar.Tabs.Size) ? target_order : selected_order];

                // Cross through buttons
                // (even if first/last item is a button, return it so we can update the scroll)
                if (tab_to_scroll_to.Flags & ImGuiTabItemFlags.Button)
                {
                    target_order += select_dir;
                    selected_order += select_dir;
                    tab_to_scroll_to = (target_order < 0 || target_order >= tab_bar.Tabs.Size) ? tab_to_scroll_to : NULL;
                }
            }
        }
    window.DC.CursorPos = backup_cursor_pos;
    tab_bar.BarRect.Max.x -= scrolling_buttons_width + 1.0f;

    return tab_to_scroll_to;
}

ImGuiTabItem* TabBarTabListPopupButton(ImGuiTabBar* tab_bar)
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;

    // We use g.Style.FramePadding.y to match the square ArrowButton size
    const float tab_list_popup_button_width = g.FontSize + g.Style.FramePadding.y;
    const ImVec2 backup_cursor_pos = window.DC.CursorPos;
    window.DC.CursorPos = ImVec2(tab_bar.BarRect.Min.x - g.Style.FramePadding.y, tab_bar.BarRect.Min.y);
    tab_bar.BarRect.Min.x += tab_list_popup_button_width;

    ImVec4 arrow_col = g.Style.Colors[ImGuiCol.Text];
    arrow_col.w *= 0.5f;
    PushStyleColor(ImGuiCol.Text, arrow_col);
    PushStyleColor(ImGuiCol.Button, ImVec4(0, 0, 0, 0));
    bool open = BeginCombo("##v", NULL, ImGuiComboFlags.NoPreview | ImGuiComboFlags.HeightLargest);
    PopStyleColor(2);

    ImGuiTabItem* tab_to_select = NULL;
    if (open)
    {
        for (int tab_n = 0; tab_n < tab_bar.Tabs.Size; tab_n++)
        {
            ImGuiTabItem* tab = &tab_bar.Tabs[tab_n];
            if (tab.Flags & ImGuiTabItemFlags.Button)
                continue;

            string tab_name = tab_bar.GetTabName(tab);
            if (Selectable(tab_name, tab_bar.SelectedTabId == tab.ID))
                tab_to_select = tab;
        }
        EndCombo();
    }

    window.DC.CursorPos = backup_cursor_pos;
    return tab_to_select;
}

//-------------------------------------------------------------------------
// [SECTION] Widgets: BeginTabItem, EndTabItem, etc.
//-------------------------------------------------------------------------
// - BeginTabItem()
// - EndTabItem()
// - TabItemButton()
// - TabItemEx() [Internal]
// - SetTabItemClosed()
// - TabItemCalcSize() [Internal]
// - TabItemBackground() [Internal]
// - TabItemLabelAndCloseButton() [Internal]
//-------------------------------------------------------------------------

bool    BeginTabItem(string label, bool* p_open = NULL, ImGuiTabItemFlags flags = ImGuiTabItemFlags.None)
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;
    if (window.SkipItems)
        return false;

    ImGuiTabBar* tab_bar = g.CurrentTabBar;
    if (tab_bar == NULL)
    {
        IM_ASSERT_USER_ERROR(tab_bar, "Needs to be called between BeginTabBar() and EndTabBar()!");
        return false;
    }
    IM_ASSERT(!(flags & ImGuiTabItemFlags.Button)); // BeginTabItem() Can't be used with button flags, use TabItemButton() instead!

    bool ret = TabItemEx(tab_bar, label, p_open, flags);
    if (ret && !(flags & ImGuiTabItemFlags.NoPushId))
    {
        ImGuiTabItem* tab = &tab_bar.Tabs[tab_bar.LastTabItemIdx];
        PushOverrideID(tab.ID); // We already hashed 'label' so push into the ID stack directly instead of doing another hash through PushID(label)
    }
    return ret;
}

void    EndTabItem()
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;
    if (window.SkipItems)
        return;

    ImGuiTabBar* tab_bar = g.CurrentTabBar;
    if (tab_bar == NULL)
    {
        IM_ASSERT_USER_ERROR(tab_bar != NULL, "Needs to be called between BeginTabBar() and EndTabBar()!");
        return;
    }
    IM_ASSERT(tab_bar.LastTabItemIdx >= 0);
    ImGuiTabItem* tab = &tab_bar.Tabs[tab_bar.LastTabItemIdx];
    if (!(tab.Flags & ImGuiTabItemFlags.NoPushId))
        PopID();
}

bool    TabItemButton(string label, ImGuiTabItemFlags flags)
{
    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;
    if (window.SkipItems)
        return false;

    ImGuiTabBar* tab_bar = g.CurrentTabBar;
    if (tab_bar == NULL)
    {
        IM_ASSERT_USER_ERROR(tab_bar != NULL, "Needs to be called between BeginTabBar() and EndTabBar()!");
        return false;
    }
    return TabItemEx(tab_bar, label, NULL, flags | ImGuiTabItemFlags.Button | ImGuiTabItemFlags.NoReorder);
}

bool    TabItemEx(ImGuiTabBar* tab_bar, string label, bool* p_open, ImGuiTabItemFlags flags)
{
    // Layout whole tab bar if not already done
    if (tab_bar.WantLayout)
        TabBarLayout(tab_bar);

    ImGuiContext* g = GImGui;
    ImGuiWindow* window = g.CurrentWindow;
    if (window.SkipItems)
        return false;

    const ImGuiStyle* style = &g.Style;
    const ImGuiID id = TabBarCalcTabID(tab_bar, label);

    // If the user called us with *p_open == false, we early out and don't render.
    // We make a call to ItemAdd() so that attempts to use a contextual popup menu with an implicit ID won't use an older ID.
    IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags);
    if (p_open && !*p_open)
    {
        PushItemFlag(ImGuiItemFlags.NoNav | ImGuiItemFlags.NoNavDefaultFocus, true);
        ItemAdd(ImRect(), id);
        PopItemFlag();
        return false;
    }

    IM_ASSERT(!p_open || !(flags & ImGuiTabItemFlags.Button));
    IM_ASSERT((flags & (ImGuiTabItemFlags.Leading | ImGuiTabItemFlags.Trailing)) != (ImGuiTabItemFlags.Leading | ImGuiTabItemFlags.Trailing)); // Can't use both Leading and Trailing

    // Store into ImGuiTabItemFlags_NoCloseButton, also honor ImGuiTabItemFlags_NoCloseButton passed by user (although not documented)
    if (flags & ImGuiTabItemFlags.NoCloseButton)
        p_open = NULL;
    else if (p_open == NULL)
        flags |= ImGuiTabItemFlags.NoCloseButton;

    // Calculate tab contents size
    ImVec2 size = TabItemCalcSize(label, p_open != NULL);

    // Acquire tab data
    ImGuiTabItem* tab = TabBarFindTabByID(tab_bar, id);
    bool tab_is_new = false;
    if (tab == NULL)
    {
        tab_bar.Tabs.push_back(ImGuiTabItem(false));
        tab = &tab_bar.Tabs.back();
        tab.ID = id;
        tab.Width = size.x;
        tab_bar.TabsAddedNew = true;
        tab_is_new = true;
    }
    tab_bar.LastTabItemIdx = cast(ImS16)tab_bar.Tabs.index_from_ptr(tab);
    tab.ContentWidth = size.x;
    tab.BeginOrder = tab_bar.TabsActiveCount++;

    const bool tab_bar_appearing = (tab_bar.PrevFrameVisible + 1 < g.FrameCount);
    const bool tab_bar_focused = (tab_bar.Flags & ImGuiTabBarFlags.IsFocused) != 0;
    const bool tab_appearing = (tab.LastFrameVisible + 1 < g.FrameCount);
    const bool is_tab_button = (flags & ImGuiTabItemFlags.Button) != 0;
    tab.LastFrameVisible = g.FrameCount;
    tab.Flags = flags;

    // Append name with zero-terminator
    tab.NameOffset = cast(ImS32)tab_bar.TabsNames.size();
    tab_bar.TabsNames.append(label);
    tab_bar.TabsNames.append("\0"); // D_IMGUI: Tabs use zero as a separator between entries

    // Update selected tab
    if (tab_appearing && (tab_bar.Flags & ImGuiTabBarFlags.AutoSelectNewTabs) && tab_bar.NextSelectedTabId == 0)
        if (!tab_bar_appearing || tab_bar.SelectedTabId == 0)
            if (!is_tab_button)
                tab_bar.NextSelectedTabId = id;  // New tabs gets activated
    if ((flags & ImGuiTabItemFlags.SetSelected) && (tab_bar.SelectedTabId != id)) // SetSelected can only be passed on explicit tab bar
        if (!is_tab_button)
            tab_bar.NextSelectedTabId = id;

    // Lock visibility
    // (Note: tab_contents_visible != tab_selected... because CTRL+TAB operations may preview some tabs without selecting them!)
    bool tab_contents_visible = (tab_bar.VisibleTabId == id);
    if (tab_contents_visible)
        tab_bar.VisibleTabWasSubmitted = true;

    // On the very first frame of a tab bar we let first tab contents be visible to minimize appearing glitches
    if (!tab_contents_visible && tab_bar.SelectedTabId == 0 && tab_bar_appearing)
        if (tab_bar.Tabs.Size == 1 && !(tab_bar.Flags & ImGuiTabBarFlags.AutoSelectNewTabs))
            tab_contents_visible = true;

    // Note that tab_is_new is not necessarily the same as tab_appearing! When a tab bar stops being submitted
    // and then gets submitted again, the tabs will have 'tab_appearing=true' but 'tab_is_new=false'.
    if (tab_appearing && (!tab_bar_appearing || tab_is_new))
    {
        PushItemFlag(ImGuiItemFlags.NoNav | ImGuiItemFlags.NoNavDefaultFocus, true);
        ItemAdd(ImRect(), id);
        PopItemFlag();
        if (is_tab_button)
            return false;
        return tab_contents_visible;
    }

    if (tab_bar.SelectedTabId == id)
        tab.LastFrameSelected = g.FrameCount;

    // Backup current layout position
    const ImVec2 backup_main_cursor_pos = window.DC.CursorPos;

    // Layout
    const bool is_central_section = (tab.Flags & ImGuiTabItemFlags.SectionMask_) == 0;
    size.x = tab.Width;
    if (is_central_section)
        window.DC.CursorPos = tab_bar.BarRect.Min + ImVec2(IM_FLOOR(tab.Offset - tab_bar.ScrollingAnim), 0.0f);
    else
        window.DC.CursorPos = tab_bar.BarRect.Min + ImVec2(tab.Offset, 0.0f);
    ImVec2 pos = window.DC.CursorPos;
    ImRect bb = ImRect(pos, pos + size);

    // We don't have CPU clipping primitives to clip the CloseButton (until it becomes a texture), so need to add an extra draw call (temporary in the case of vertical animation)
    const bool want_clip_rect = is_central_section && (bb.Min.x < tab_bar.ScrollingRectMinX || bb.Max.x > tab_bar.ScrollingRectMaxX);
    if (want_clip_rect)
        PushClipRect(ImVec2(ImMax(bb.Min.x, tab_bar.ScrollingRectMinX), bb.Min.y - 1), ImVec2(tab_bar.ScrollingRectMaxX, bb.Max.y), true);

    ImVec2 backup_cursor_max_pos = window.DC.CursorMaxPos;
    ItemSize(bb.GetSize(), style.FramePadding.y);
    window.DC.CursorMaxPos = backup_cursor_max_pos;

    if (!ItemAdd(bb, id))
    {
        if (want_clip_rect)
            PopClipRect();
        window.DC.CursorPos = backup_main_cursor_pos;
        return tab_contents_visible;
    }

    // Click to Select a tab
    ImGuiButtonFlags button_flags = ((is_tab_button ? ImGuiButtonFlags.PressedOnClickRelease : ImGuiButtonFlags.PressedOnClick) | ImGuiButtonFlags.AllowItemOverlap);
    if (g.DragDropActive)
        button_flags |= ImGuiButtonFlags.PressedOnDragDropHold;
    bool hovered, held;
    bool pressed = ButtonBehavior(bb, id, &hovered, &held, button_flags);
    if (pressed && !is_tab_button)
        tab_bar.NextSelectedTabId = id;

    // Allow the close button to overlap unless we are dragging (in which case we don't want any overlapping tabs to be hovered)
    if (g.ActiveId != id)
        SetItemAllowOverlap();

    // Drag and drop: re-order tabs
    if (held && !tab_appearing && IsMouseDragging(ImGuiMouseButton.Left))
    {
        if (!g.DragDropActive && (tab_bar.Flags & ImGuiTabBarFlags.Reorderable))
        {
            // While moving a tab it will jump on the other side of the mouse, so we also test for MouseDelta.x
            if (g.IO.MouseDelta.x < 0.0f && g.IO.MousePos.x < bb.Min.x)
            {
                TabBarQueueReorderFromMousePos(tab_bar, tab, g.IO.MousePos);
            }
            else if (g.IO.MouseDelta.x > 0.0f && g.IO.MousePos.x > bb.Max.x)
            {
                TabBarQueueReorderFromMousePos(tab_bar, tab, g.IO.MousePos);
            }
        }
    }

static if (false) {
    if (hovered && g.HoveredIdNotActiveTimer > TOOLTIP_DELAY && bb.GetWidth() < tab.ContentWidth)
    {
        // Enlarge tab display when hovering
        bb.Max.x = bb.Min.x + IM_FLOOR(ImLerp(bb.GetWidth(), tab.ContentWidth, ImSaturate((g.HoveredIdNotActiveTimer - 0.40f) * 6.0f)));
        display_draw_list = GetForegroundDrawList(window);
        TabItemBackground(display_draw_list, bb, flags, GetColorU32(ImGuiCol.TitleBgActive));
    }
}

    // Render tab shape
    ImDrawList* display_draw_list = window.DrawList;
    const ImU32 tab_col = GetColorU32((held || hovered) ? ImGuiCol.TabHovered : tab_contents_visible ? (tab_bar_focused ? ImGuiCol.TabActive : ImGuiCol.TabUnfocusedActive) : (tab_bar_focused ? ImGuiCol.Tab : ImGuiCol.TabUnfocused));
    TabItemBackground(display_draw_list, bb, flags, tab_col);
    RenderNavHighlight(bb, id);

    // Select with right mouse button. This is so the common idiom for context menu automatically highlight the current widget.
    const bool hovered_unblocked = IsItemHovered(ImGuiHoveredFlags.AllowWhenBlockedByPopup);
    if (hovered_unblocked && (IsMouseClicked(ImGuiMouseButton.Right) || IsMouseReleased(ImGuiMouseButton.Right)))
        if (!is_tab_button)
            tab_bar.NextSelectedTabId = id;

    if (tab_bar.Flags & ImGuiTabBarFlags.NoCloseWithMiddleMouseButton)
        flags |= ImGuiTabItemFlags.NoCloseWithMiddleMouseButton;

    // Render tab label, process close button
    const ImGuiID close_button_id = p_open ? GetIDWithSeed("#CLOSE", id) : 0;
    bool just_closed;
    bool text_clipped;
    TabItemLabelAndCloseButton(display_draw_list, bb, flags, tab_bar.FramePadding, label, id, close_button_id, tab_contents_visible, &just_closed, &text_clipped);
    if (just_closed && p_open != NULL)
    {
        *p_open = false;
        TabBarCloseTab(tab_bar, tab);
    }

    // Restore main window position so user can draw there
    if (want_clip_rect)
        PopClipRect();
    window.DC.CursorPos = backup_main_cursor_pos;

    // Tooltip
    // (Won't work over the close button because ItemOverlap systems messes up with HoveredIdTimer-> seems ok)
    // (We test IsItemHovered() to discard e.g. when another item is active or drag and drop over the tab bar, which g.HoveredId ignores)
    // FIXME: This is a mess.
    // FIXME: We may want disabled tab to still display the tooltip?
    if (text_clipped && g.HoveredId == id && !held && g.HoveredIdNotActiveTimer > g.TooltipSlowDelay && IsItemHovered())
        if (!(tab_bar.Flags & ImGuiTabBarFlags.NoTooltip) && !(tab.Flags & ImGuiTabItemFlags.NoTooltip))
            SetTooltip("%s", FindRenderedTextEnd(label));

    IM_ASSERT(!is_tab_button || !(tab_bar.SelectedTabId == tab.ID && is_tab_button)); // TabItemButton should not be selected
    if (is_tab_button)
        return pressed;
    return tab_contents_visible;
}

// [Public] This is call is 100% optional but it allows to remove some one-frame glitches when a tab has been unexpectedly removed.
// To use it to need to call the function SetTabItemClosed() between BeginTabBar() and EndTabBar().
// Tabs closed by the close button will automatically be flagged to avoid this issue.
void    SetTabItemClosed(string label)
{
    ImGuiContext* g = GImGui;
    bool is_within_manual_tab_bar = g.CurrentTabBar && !(g.CurrentTabBar.Flags & ImGuiTabBarFlags.DockNode);
    if (is_within_manual_tab_bar)
    {
        ImGuiTabBar* tab_bar = g.CurrentTabBar;
        ImGuiID tab_id = TabBarCalcTabID(tab_bar, label);
        if (ImGuiTabItem* tab = TabBarFindTabByID(tab_bar, tab_id))
            tab.WantClose = true; // Will be processed by next call to TabBarLayout()
    }
}

ImVec2 TabItemCalcSize(string label, bool has_close_button)
{
    ImGuiContext* g = GImGui;
    ImVec2 label_size = CalcTextSize(label, true);
    ImVec2 size = ImVec2(label_size.x + g.Style.FramePadding.x, label_size.y + g.Style.FramePadding.y * 2.0f);
    if (has_close_button)
        size.x += g.Style.FramePadding.x + (g.Style.ItemInnerSpacing.x + g.FontSize); // We use Y intentionally to fit the close button circle.
    else
        size.x += g.Style.FramePadding.x + 1.0f;
    return ImVec2(ImMin(size.x, TabBarCalcMaxTabWidth()), size.y);
}

void TabItemBackground(ImDrawList* draw_list, const ImRect/*&*/ bb, ImGuiTabItemFlags flags, ImU32 col)
{
    // While rendering tabs, we trim 1 pixel off the top of our bounding box so they can fit within a regular frame height while looking "detached" from it.
    ImGuiContext* g = GImGui;
    const float width = bb.GetWidth();
    IM_UNUSED(flags);
    IM_ASSERT(width > 0.0f);
    const float rounding = ImMax(0.0f, ImMin((flags & ImGuiTabItemFlags.Button) ? g.Style.FrameRounding : g.Style.TabRounding, width * 0.5f - 1.0f));
    const float y1 = bb.Min.y + 1.0f;
    const float y2 = bb.Max.y - 1.0f;
    draw_list.PathLineTo(ImVec2(bb.Min.x, y2));
    draw_list.PathArcToFast(ImVec2(bb.Min.x + rounding, y1 + rounding), rounding, 6, 9);
    draw_list.PathArcToFast(ImVec2(bb.Max.x - rounding, y1 + rounding), rounding, 9, 12);
    draw_list.PathLineTo(ImVec2(bb.Max.x, y2));
    draw_list.PathFillConvex(col);
    if (g.Style.TabBorderSize > 0.0f)
    {
        draw_list.PathLineTo(ImVec2(bb.Min.x + 0.5f, y2));
        draw_list.PathArcToFast(ImVec2(bb.Min.x + rounding + 0.5f, y1 + rounding + 0.5f), rounding, 6, 9);
        draw_list.PathArcToFast(ImVec2(bb.Max.x - rounding - 0.5f, y1 + rounding + 0.5f), rounding, 9, 12);
        draw_list.PathLineTo(ImVec2(bb.Max.x - 0.5f, y2));
        draw_list.PathStroke(GetColorU32(ImGuiCol.Border), ImDrawFlags.None, g.Style.TabBorderSize);
    }
}

// Render text label (with custom clipping) + Unsaved Document marker + Close Button logic
// We tend to lock style.FramePadding for a given tab-bar, hence the 'frame_padding' parameter.
void TabItemLabelAndCloseButton(ImDrawList* draw_list, const ImRect/*&*/ bb, ImGuiTabItemFlags flags, ImVec2 frame_padding, string label, ImGuiID tab_id, ImGuiID close_button_id, bool is_contents_visible, bool* out_just_closed, bool* out_text_clipped)
{
    ImGuiContext* g = GImGui;
    ImVec2 label_size = CalcTextSize(label, true);

    if (out_just_closed)
        *out_just_closed = false;
    if (out_text_clipped)
        *out_text_clipped = false;

    if (bb.GetWidth() <= 1.0f)
        return;

    // In Style V2 we'll have full override of all colors per state (e.g. focused, selected)
    // But right now if you want to alter text color of tabs this is what you need to do.
static if (false) {
    const float backup_alpha = g.Style.Alpha;
    if (!is_contents_visible)
        g.Style.Alpha *= 0.7f;
}

    // Render text label (with clipping + alpha gradient) + unsaved marker
    ImRect text_pixel_clip_bb = ImRect(bb.Min.x + frame_padding.x, bb.Min.y + frame_padding.y, bb.Max.x - frame_padding.x, bb.Max.y);
    ImRect text_ellipsis_clip_bb = text_pixel_clip_bb;

    // Return clipped state ignoring the close button
    if (out_text_clipped)
    {
        *out_text_clipped = (text_ellipsis_clip_bb.Min.x + label_size.x) > text_pixel_clip_bb.Max.x;
        //draw_list->AddCircle(text_ellipsis_clip_bb.Min, 3.0f, *out_text_clipped ? IM_COL32(255, 0, 0, 255) : IM_COL32(0, 255, 0, 255));
    }

    const float button_sz = g.FontSize;
    const ImVec2 button_pos = ImVec2(ImMax(bb.Min.x, bb.Max.x - frame_padding.x * 2.0f - button_sz), bb.Min.y);

    // Close Button & Unsaved Marker
    // We are relying on a subtle and confusing distinction between 'hovered' and 'g.HoveredId' which happens because we are using ImGuiButtonFlags_AllowOverlapMode + SetItemAllowOverlap()
    //  'hovered' will be true when hovering the Tab but NOT when hovering the close button
    //  'g.HoveredId==id' will be true when hovering the Tab including when hovering the close button
    //  'g.ActiveId==close_button_id' will be true when we are holding on the close button, in which case both hovered booleans are false
    bool close_button_pressed = false;
    bool close_button_visible = false;
    if (close_button_id != 0)
        if (is_contents_visible || bb.GetWidth() >= ImMax(button_sz, g.Style.TabMinWidthForCloseButton))
            if (g.HoveredId == tab_id || g.HoveredId == close_button_id || g.ActiveId == tab_id || g.ActiveId == close_button_id)
                close_button_visible = true;
    bool unsaved_marker_visible = (flags & ImGuiTabItemFlags.UnsavedDocument) != 0 && (button_pos.x + button_sz <= bb.Max.x);

    if (close_button_visible)
    {
        ImGuiLastItemData last_item_backup = g.LastItemData;
        PushStyleVar(ImGuiStyleVar.FramePadding, frame_padding);
        if (CloseButton(close_button_id, button_pos))
            close_button_pressed = true;
        PopStyleVar();
        g.LastItemData = last_item_backup;

        // Close with middle mouse button
        if (!(flags & ImGuiTabItemFlags.NoCloseWithMiddleMouseButton) && IsMouseClicked(ImGuiMouseButton.Middle))
            close_button_pressed = true;
    }
    else if (unsaved_marker_visible)
    {
        const ImRect bullet_bb = ImRect(button_pos, button_pos + ImVec2(button_sz, button_sz) + g.Style.FramePadding * 2.0f);
        RenderBullet(draw_list, bullet_bb.GetCenter(), GetColorU32(ImGuiCol.Text));
    }

    // This is all rather complicated
    // (the main idea is that because the close button only appears on hover, we don't want it to alter the ellipsis position)
    // FIXME: if FramePadding is noticeably large, ellipsis_max_x will be wrong here (e.g. #3497), maybe for consistency that parameter of RenderTextEllipsis() shouldn't exist..
    float ellipsis_max_x = close_button_visible ? text_pixel_clip_bb.Max.x : bb.Max.x - 1.0f;
    if (close_button_visible || unsaved_marker_visible)
    {
        text_pixel_clip_bb.Max.x -= close_button_visible ? (button_sz) : (button_sz * 0.80f);
        text_ellipsis_clip_bb.Max.x -= unsaved_marker_visible ? (button_sz * 0.80f) : 0.0f;
        ellipsis_max_x = text_pixel_clip_bb.Max.x;
    }
    RenderTextEllipsis(draw_list, text_ellipsis_clip_bb.Min, text_ellipsis_clip_bb.Max, text_pixel_clip_bb.Max.x, ellipsis_max_x, label, &label_size);

static if (false) {
    if (!is_contents_visible)
        g.Style.Alpha = backup_alpha;
}

    if (out_just_closed)
        *out_just_closed = close_button_pressed;
}


// #endif // #ifndef IMGUI_DISABLE
