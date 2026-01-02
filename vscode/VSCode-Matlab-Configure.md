# VS Code MATLAB Extension Setup Guide

This guide documents how to configure VS Code for MATLAB development on macOS.

## 1. Install the MATLAB Extension

1. Open VS Code
2. Go to Extensions (`Cmd+Shift+X`)
3. Search for "MATLAB" by MathWorks
4. Click **Install**, then **Enable**

## 2. Configure VS Code Settings

Open settings JSON: `Cmd+Shift+P` → "Preferences: Open User Settings (JSON)"

**File location on macOS:**
```
~/Library/Application Support/Code/User/settings.json
```

Add these settings (adjust the MATLAB version as needed):

```json
{
    "MATLAB.installPath": "/Applications/MATLAB_R2025b.app",
    "MATLAB.matlabConnectionTiming": "onStart"
}
```

### Finding Your MATLAB Path

In MATLAB, run:
```matlab
matlabroot
```

Use the returned path for `MATLAB.installPath`.

## 3. Configure startup.m for Non-Interactive Sessions

VS Code launches MATLAB without the desktop GUI, so interactive prompts in `startup.m` will hang the connection.

Add this to the **top** of your `startup.m`:

```matlab
% Skip interactive setup when running without desktop (e.g., VS Code)
if ~usejava('desktop')
    % Optionally set default paths here
    addpath(genpath('/Users/wandell/Documents/MATLAB/vistasoft'));
    return
end

% Rest of your normal startup code (interactive prompts, etc.)
```

### startup.m Location

Common locations:
- `~/Documents/MATLAB/startup.m`
- Custom path set in MATLAB preferences

Find yours with:
```matlab
which startup
```

## 4. Verify Connection

1. Open any `.m` file in VS Code
2. Watch the status bar at the bottom
3. Should progress: "MATLAB: Starting..." → "MATLAB: Ready"

If stuck on "Establishing Connection":
- Check your `startup.m` for interactive prompts
- Reload VS Code: `Cmd+Shift+P` → "Developer: Reload Window"

## 5. Key Bindings (macOS)

| Action | Shortcut |
|--------|----------|
| Run entire file | `F5` |
| Run current selection | `Shift+Enter` |
| Run current section | `Control+Enter` |
| Open Command Palette | `Cmd+Shift+P` |
| Go to file | `Cmd+P` |
| Search in workspace | `Cmd+Shift+F` |

### Sections

Define sections in your code with `%%`:

```matlab
%% Section 1 - Load data
data = load('myfile.mat');

%% Section 2 - Process
result = process(data);

%% Section 3 - Plot
plot(result);
```

Use `Control+Enter` to run the section where your cursor is located.

## 6. Troubleshooting

### MATLAB won't connect
- Close any running MATLAB instances
- Check `MATLAB.installPath` is correct
- Reload VS Code

### Settings key appears dim/unrecognized
- Use uppercase `MATLAB` prefix (not `matlab`)
- Correct: `"MATLAB.installPath"`
- Wrong: `"matlab.installPath"`

### Connection hangs
- Your `startup.m` likely has interactive prompts
- Add the non-desktop check shown in Section 3

## 7. Useful Commands (Command Palette)

Access via `Cmd+Shift+P`:

- `MATLAB: Run File`
- `MATLAB: Run Current Section`
- `MATLAB: Run Current Selection`
- `MATLAB: Open Command Window`
- `MATLAB: Change MATLAB Connection`

---

*Created: January 2026*
