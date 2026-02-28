# Completion Report

**Playbook:** {{ playbook_name }}
**Design Doc:** {{ design_doc_path }}
**Completed:** {{ date }}
**Branch:** {{ branch_name }}

## Summary

{{ 2-3 sentence summary of what was built }}

## Requirements Mapping

| Requirement | Status | Implementation | Notes |
|-------------|--------|----------------|-------|
| {{ req }} | Done/Deferred/Modified | {{ file:line }} | {{ rationale if modified }} |

## Guardian Results

### Spec Guardian
- Issues caught: {{ count }}
- All resolved: Yes/No
- Details: {{ list of issues and resolutions }}

### Test Guardian
- Issues caught: {{ count }}
- All resolved: Yes/No
- Test command: {{ command }}
- Final result: PASS/FAIL
- Details: {{ list of issues and resolutions }}

### Convention Guardian
- Issues caught: {{ count }}
- All resolved: Yes/No
- Details: {{ list of issues and resolutions }}

### Integration Guardian
- Issues caught: {{ count }}
- All resolved: Yes/No
- Full suite result: PASS/FAIL
- Details: {{ list of issues and resolutions }}

## Deviations from Spec

{{ List of any changes from the original design, with rationale from the Reviewer }}

## Test Results

```
{{ Paste of final test run output }}
```

## Key Decisions

{{ Rolled-up summary from decisions log }}
