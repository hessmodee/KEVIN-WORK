from pathlib import Path
import re
import unittest

HTML = Path(__file__).with_name('mobile_panel.html').read_text(encoding='utf-8')
LOW = HTML.lower()


class MobilePanelContractTests(unittest.TestCase):
    def test_viewport_and_phone_breakpoints(self):
        self.assertIn('width=device-width', LOW)
        compact = LOW.replace(' ', '')
        self.assertIn('@media(max-width:430px)', compact)
        self.assertIn('@media(max-width:360px)', compact)

    def test_no_horizontal_page_scroll_contract(self):
        compact = re.sub(r'\s+', '', LOW)
        self.assertIn('overflow-x:hidden', compact)
        self.assertIn('max-width:100%', compact)
        self.assertIn('min-width:0', compact)

    def test_touch_targets_are_at_least_44px(self):
        m = re.search(r'button\{[^}]*min-height:(\d+)px', LOW, flags=re.S)
        self.assertIsNotNone(m)
        self.assertGreaterEqual(int(m.group(1)), 44)

    def test_text_entry_avoids_mobile_zoom(self):
        m = re.search(r'textarea\{[^}]*font-size:(\d+)px', LOW, flags=re.S)
        self.assertIsNotNone(m)
        self.assertGreaterEqual(int(m.group(1)), 16)

    def test_truthful_transport_default(self):
        self.assertIn('data-private-transport="unavailable"', LOW)
        self.assertIn('disabled>send</button>', LOW)
        self.assertIn('not installed', LOW)
        self.assertIn('ready===true', LOW.replace(' ', ''))

    def test_fixed_lifecycle_only(self):
        compact = LOW.replace(' ', '')
        for state in ('queued', 'received', 'thinking', 'replied', 'failed'):
            self.assertIn("'" + state + "'", compact)
        self.assertIn('invalid lifecycle state', LOW)

    def test_no_public_network_or_secret_surface(self):
        forbidden = [
            'fetch(', 'xmlhttprequest', 'websocket(', 'eventsource(',
            'authorization:', 'bearer ', 'bot_token', 'chat_id',
            'client_secret', 'refresh_token', 'password=', 'localstorage',
            'sessionstorage', 'document.cookie'
        ]
        bad = [x for x in forbidden if x in LOW]
        self.assertEqual([], bad, 'forbidden public surface: ' + ', '.join(bad))

    def test_message_is_dispatched_as_intent_not_code(self):
        self.assertIn("customevent('kevin-hq-owner-message'", LOW)
        for forbidden in ('eval(', 'exec(', 'powershell', 'cmd.exe', 'subprocess'):
            self.assertNotIn(forbidden, LOW)


if __name__ == '__main__':
    unittest.main()
