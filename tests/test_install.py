import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.env = dict(os.environ, HOME=str(self.home),
                        XDG_STATE_HOME=str(self.home / 'state'))
        self.target = self.home / '.config/omarchy/themes/osaka-blue-glow'

    def run_install(self, *args):
        return subprocess.run(['bash', str(ROOT / 'install.sh'), *args],
                              env=self.env, text=True, capture_output=True)

    def test_complete_local_install_without_git_or_development_files(self):
        result = self.run_install('--no-apply')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.target / 'hyprland.lua').read_bytes(),
                         (ROOT / 'hyprland.lua').read_bytes())
        self.assertEqual(len(list((self.target / 'backgrounds').iterdir())), 2)
        self.assertFalse((self.target / '.git').exists())
        self.assertFalse((self.target / 'tools').exists())
        self.assertFalse((self.target / 'install.sh').exists())

    def test_existing_theme_is_preserved_in_backup(self):
        self.target.mkdir(parents=True)
        (self.target / 'personal-setting').write_text('keep me')
        result = self.run_install('--no-apply')
        self.assertEqual(result.returncode, 0, result.stderr)
        backup_root = self.home / 'state/omarchy/theme-backups/osaka-blue-glow'
        backups = list(backup_root.iterdir())
        self.assertEqual(len(backups), 1)
        self.assertEqual((backups[0] / 'personal-setting').read_text(), 'keep me')
        self.assertFalse((self.target / 'personal-setting').exists())

    def test_apply_selects_requested_wallpaper_and_validates_hyprland(self):
        bin_dir = self.home / 'bin'
        bin_dir.mkdir()
        log = self.home / 'commands.log'
        for name in ('omarchy', 'hyprctl'):
            stub = bin_dir / name
            stub.write_text('#!/bin/bash\nprintf "%s %s\\n" "$(basename "$0")" "$*" >> "$TEST_LOG"\n')
            stub.chmod(0o755)
        self.env.update(PATH=str(bin_dir) + os.pathsep + os.environ['PATH'],
                        TEST_LOG=str(log))
        for args, wallpaper in [((), '1-osaka-blue-night-animated.mp4'),
                                (('--still',), '0-osaka-blue-night.png')]:
            with self.subTest(args=args):
                log.write_text('')
                result = self.run_install(*args)
                self.assertEqual(result.returncode, 0, result.stderr)
                commands = log.read_text()
                self.assertIn('omarchy theme set Osaka Blue Glow', commands)
                self.assertIn('omarchy theme bg set ' + str(self.home) +
                              '/.local/state/omarchy/current/theme/backgrounds/' + wallpaper,
                              commands)
                self.assertIn('hyprctl reload', commands)
                self.assertIn('hyprctl configerrors', commands)

    def test_unknown_option_does_not_change_files(self):
        result = self.run_install('--invalid')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.target.exists())


if __name__ == '__main__':
    unittest.main()
