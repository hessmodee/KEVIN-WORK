import copy
import unittest

from contract import ContractError, assert_only_known_repair_diff, build_known_repair_intents, classify_main_config, semantic_leaf_diff
from contract import classify_tool_policy_surfaces
from test_contract import base_config


class SafetyNegatives(unittest.TestCase):
    def test_malformed_tool_policy_objects_rejected(self):
        cases = [
            lambda c: c.update(tools=[]),
            lambda c: c['agents']['entries']['main'].update(tools=[]),
            lambda c: c['tools'].update(byProvider=[]),
            lambda c: c['tools'].update(toolsBySender=[]),
            lambda c: c['tools'].update(sandbox=[]),
            lambda c: c['tools'].update(byProvider={'ollama-chat-16k': []}),
            lambda c: c['tools'].update(toolsBySender={'*': []}),
        ]
        for mutate in cases:
            with self.subTest(mutate=mutate):
                cfg = base_config()
                mutate(cfg)
                with self.assertRaises(ContractError):
                    classify_tool_policy_surfaces(cfg)

    def test_unknown_profiles_rejected_at_each_policy_layer(self):
        cases = [
            lambda c: c['tools'].update(profile='unknown'),
            lambda c: c['tools'].update(byProvider={'ollama-chat-16k': {'profile': 'unknown'}}),
            lambda c: c['tools'].update(toolsBySender={'*': {'profile': 'unknown'}}),
        ]
        for mutate in cases:
            with self.subTest(mutate=mutate):
                cfg = base_config()
                mutate(cfg)
                with self.assertRaises(ContractError):
                    classify_tool_policy_surfaces(cfg)

    def test_allow_and_also_allow_rejected_even_when_empty(self):
        cfg = base_config()
        cfg['tools']['allow'] = []
        cfg['tools']['alsoAllow'] = []
        with self.assertRaises(ContractError):
            classify_tool_policy_surfaces(cfg)

    def test_explicit_empty_policy_is_distinguished_from_absence(self):
        cfg = base_config()
        cfg['agents']['entries']['main']['tools'] = {}
        result = classify_tool_policy_surfaces(cfg)
        self.assertTrue(result['main']['present'])
        self.assertEqual(result['main']['profile'], 'UNSET')

    def test_provider_sender_and_sandbox_presence_reported_without_effective_claim(self):
        cfg = base_config()
        cfg['tools'].update(
            byProvider={'ollama-chat-16k': {'profile': 'minimal'}},
            toolsBySender={'*': {'deny': ['group:runtime']}},
            sandbox={},
        )
        result = classify_tool_policy_surfaces(cfg)
        self.assertTrue(result['root']['provider_policy_present'])
        self.assertEqual(result['root']['provider_policy_count'], 1)
        self.assertTrue(result['root']['sender_policy_present'])
        self.assertEqual(result['root']['sender_policy_count'], 1)
        self.assertTrue(result['root']['sandbox_policy_present'])
        self.assertIn('session-effective', result['truth_boundary'])

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
