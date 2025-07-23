# Contributing to Perseus

Thank you for your interest in making Perseus better! This guide will help you contribute effectively.

## 🎯 Current Priority Areas

### High Priority
1. **Login Manager Improvements**
   - Current LightDM setup needs aesthetic work
   - Consider alternatives like `greetd` + `tuigreet` or `lemurs`
   - Must be stable - no experimental/broken greeters
   - Should support our custom avatar system

2. **Security Audit Enhancements**
   - Better NixOS-specific checks in NastyTechLords
   - Integration with `vulnix` for CVE scanning
   - Reduce false positives from chkrootkit

3. **Developer Experience**
   - More language support modules (Java, C++, Zig)
   - Better LSP configurations
   - Integrated debugging support

### Medium Priority
- Wayland support (currently X11 only)
- Secrets management (agenix or sops-nix)
- Backup automation (BorgBackup)
- Multi-monitor improvements

### Nice to Have
- Custom Perseus ISO
- Theme switcher (dark/light modes)

## 📋 Contribution Guidelines

### Code Standards

1. **Indentation**: Use TABS, not spaces (NixOS convention)
2. **Formatting**: Follow existing style in each module
3. **Comments**: Document non-obvious configuration choices
4. **Modularity**: One concern per file

### Stability Requirements

**CRITICAL**: Perseus values stability over bleeding edge.

✅ **DO**:
- Use stable nixpkgs branches
- Test on fresh VMs before submitting
- Prefer packages in nixpkgs over overlays
- Document any workarounds needed

❌ **DON'T**:
- Add experimental/unstable packages
- Use packages marked as broken
- Include untested configurations
- Break existing functionality

### Testing Checklist

Before submitting a PR, ensure:

- [ ] System builds without errors
- [ ] Can reboot successfully
- [ ] Core functionality works (network, display, audio)
- [ ] No new security warnings in `ntl run`
- [ ] Changes work on both GPU and non-GPU configs

## 🔧 Development Setup

```bash
# Fork and clone
git clone https://github.com/yourusername/perseus
cd perseus

# Create feature branch
git checkout -b feature/better-greeter

# Test in VM
nixos-rebuild build-vm --flake .#perseus
./result/bin/run-*-vm

# Make changes and test
sudo nixos-rebuild test --flake .#perseus
```

## 📝 Pull Request Process

1. **Branch Naming**: `feature/description` or `fix/description`
2. **Commit Messages**: Clear, descriptive (e.g., "Add greetd with tuigreet for better login UX")
3. **PR Description**: 
   - What problem does this solve?
   - What approach did you take?
   - Any breaking changes?
   - Screenshots if UI changes

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tested on VM
- [ ] Tested on real hardware
- [ ] Works with GPU config
- [ ] Works without GPU config

## Screenshots
(if applicable)
```

## 🎨 Specific Improvement Ideas

### Login Manager Replacement

```nix
# Example: greetd + tuigreet approach
services.greetd = {
  enable = true;
  settings = {
    default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd i3";
    };
  };
};
```

Consider:
- Must support our avatar system
- Should look modern but not bloated
- Fast startup time
- Fingerprint support

### Better Theming

- Consistent color scheme across all apps
- Nord theme is current default
- Consider Catppuccin as alternative
- Must work in both CLI and GUI

## 🚫 What NOT to Submit

- Anything that phones home
- Proprietary software (unless optional like Steam)
- Major architectural changes without discussion
- Code copied without attribution
- Features that break existing workflows

## 💬 Getting Help

- Open an issue for discussion before major changes
- Ask in PR if unsure about approach
- Check existing modules for patterns
- Test, test, test!

## 🏆 Recognition

Contributors will be added to the README with their area of contribution.

---

*Remember: We're building a fortress against tech overlords, not inviting them in! Every line of code should enhance privacy, productivity, or both.*
