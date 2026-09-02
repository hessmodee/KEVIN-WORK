import copy
import unittest

from contract import ContractError, assert_only_known_repair_diff, build_known_repair_intents, classify_main_config, semantic_leaf_diff
from test_contract import base_config


class SafetyNegatives(unittest.TestCase):
    def test_integer_contract_fields_reject_other_types(self):
        for field, value in [('reserveTokensFloor', 2048.0), ('reserveTokens', True), ('keepRecentTokens', 4000.5), ('keepRecentTokens', '4000')]:
            with self.subTest(field=field, value=value):
                cfg = base_config()
                cfg['agents']['defaults']['compaction'][field] = value
                with self.assertRaises(ContractError):
                    build_known_repair_intents(cfg)

    def test_context_float_rejected(self):
        cfg = base_config()
        cfg['models']['providers']['ollama-chat-16k']['models'][0]['contextTokens'] = 16384.0
        self.assertFalse(classify_main_config(cfg)['classification']['safe_exact_repair'])

    def test_nonfinite_values_rejected(self):
        for value in [float('inf'), float('-inf'), float('nan')]:
            with self.subTest(value=value):
                with self.assertRaises(ContractError):
                    semantic_leaf_diff({'x': value}, {'x': value})

    def test_literal_allowed_path_cannot_hide_mutation(self):
        before = base_config()
        before['agents.defaults.compaction.reserveTokens'] = 1
        after = copy.deepcopy(before)
        after['agents.defaults.compaction.reserveTokens'] = 2
        after['agents']['defaults']['compaction'].update(reserveTokens=2048, keepRecentTokens=4000)
        with self.assertRaises(ContractError):
            assert_only_known_repair_diff(before, after)

    def test_fractional_reserve_rejected(self):
        cfg = base_config()
        cfg['agents']['defaults']['compaction']['reserveTokens'] = 2048.5
        with self.assertRaises(ContractError):
            build_known_repair_intents(cfg)

    def test_numeric_string_reserve_rejected(self):
        cfg = base_config()
        cfg['agents']['defaults']['compaction']['reserveTokens'] = '2048'
        with self.assertRaises(ContractError):
            build_known_repair_intents(cfg)

    def test_explicit_null_is_not_absence(self):
        cfg = base_config()
        cfg['agents']['defaults']['compaction']['reserveTokens'] = None
        with self.assertRaises(ContractError):
            build_known_repair_intents(cfg)

    def test_boolean_integer_change_detected(self):
        self.assertTrue(semantic_leaf_diff({'enabled': True}, {'enabled': 1}))

    def test_empty_object_string_change_detected(self):
        self.assertTrue(semantic_leaf_diff({'policy': {}}, {'policy': '<EMPTY_OBJECT>'}))

    def test_empty_array_string_change_detected(self):
        self.assertTrue(semantic_leaf_diff({'policy': []}, {'policy': '<EMPTY_ARRAY>'}))

    def test_dotted_key_collision_detected(self):
        self.assertTrue(semantic_leaf_diff({'a.b': 1}, {'a': {'b': 1}}))

    def test_array_key_collision_detected(self):
        self.assertTrue(semantic_leaf_diff({'a[0]': 1}, {'a': [1]}))

    def test_unrelated_boolean_change_blocks_repair(self):
        before = base_config()
        before['enabled'] = True
        after = copy.deepcopy(before)
        after['enabled'] = 1
        after['agents']['defaults']['compaction'].update(reserveTokens=2048, keepRecentTokens=4000)
        with self.assertRaises(ContractError):
            assert_only_known_repair_diff(before, after)


if __name__ == '__main__':
    unittest.main()
