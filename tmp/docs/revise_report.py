from __future__ import annotations

import json
from pathlib import Path

from docx import Document


INPUT_DOCX = Path(r"C:/Users/abel/Desktop/YS2_NN1_mie8888-final-report.docx")
OUTPUT_DIR = Path(r"C:/Users/abel/Desktop/MIE8888/mie8888/output/doc")
OUTPUT_DOCX = OUTPUT_DIR / "revised_report.docx"
OUTPUT_JSON = OUTPUT_DIR / "revised_report_changes.json"


REPLACEMENTS = {
    5: (
        "This report studies interceptor assignment in a mobile wireless sensor network "
        "(WSN) used for cooperative multi-target tracking. In the original simulation "
        "(V45), conflict resolution was based on a MinMax objective that attempts to "
        "minimize the worst team cost among the requested targets. This objective "
        "protects the weakest target assignment, but it does not directly optimize the "
        "total resource burden imposed on the sensor network. In the DES, interceptor "
        "assignment proceeds through three event steps: broadcast, bidding, and "
        "selection. Because different targets may enter this process at different "
        "times, a new request may compete with interceptors already committed to "
        "another target. When this happens, an interceptor assignment conflict occurs."
    ),
    6: (
        "The proposed (V46) assignment reformulates the problem as a global assignment "
        "problem. In V45, this conflict-handling logic is only enforced within the "
        "current assignment procedure. V46 extends the same conflict management to "
        "later requests that compete for interceptors already committed to another "
        "target by regrouping the affected targets into one joint reassignment."
    ),
    7: (
        "The report compares the global assignment method and the minimax method using "
        "the same candidate sensors and the same cost matrices. A natural simulation "
        "conflict is used as the primary worked example. In that event, the global "
        "assignment method selects the optimal interceptors and reduces the total "
        "assignment cost compared to the minimax method. In addition, when conflicts "
        "occur, the proposed method performs a joint reassignment across affected "
        "targets, preventing a later target from taking over interceptors already "
        "committed to an earlier target, and reassigning sensors if necessary so that "
        "the earlier target is not left with fewer interceptors than the joint "
        "solution allows. These results demonstrate that the proposed method improves "
        "global assignment quality by minimizing total cost, while preventing "
        "conflict-induced reductions in the number of assigned interceptors that could "
        "increase the risk of target loss, thereby enhancing overall system stability."
    ),
    11: (
        "The central problem addressed in this report is interceptor assignment during "
        "proactive handover. When an active tracker predicts that it will lose a "
        "target, idle or non-tracking sensors are dispatched toward a predicted "
        "interception point before the target is lost. In the DES, this interceptor "
        "assignment process consists of broadcast, bidding, and selection; therefore, "
        "the system has the states PENDING_BROADCAST, PENDING_BIDDING, and "
        "PENDING_SELECTION. Because different targets may enter this process at "
        "different times, one target may start a new request while another target's "
        "selected interceptors are already executing an interception task. If those "
        "requests compete for the same sensors, independent target-by-target bidding "
        "can create conflicts, duplicate assignments, or unnecessary reassignment of "
        "sensors. Moreover, due to limited sensor availability and feasibility "
        "constraints, some targets may receive fewer than the desired maximum number "
        "of interceptors."
    ),
    13: (
        "The original conflict-resolution method used a minimax objective. When "
        "affected targets compete for the same candidate sensors, the minimax method "
        "attempted to select teams such that the worst target team cost was minimized. "
        "This is a fairness-oriented objective: no target should receive a very poor "
        "team if a more balanced solution is available. However, in the DES, conflict "
        "is not limited to requests handled within the same assignment procedure. A "
        "conflict also occurs when a new request competes with "
        "interceptors already committed to another target. In V45, the "
        "conflict-handling logic is only enforced within the current assignment "
        "procedure, so a later request may still select interceptors that have "
        "already been committed to another target. In V46, the interceptor "
        "assignment problem is formulated as a global optimization problem and solved "
        "with a joint reassignment mechanism. The method applies the same conflict "
        "condition to committed interceptors, groups the affected targets into one "
        "assignment problem, first maximizes the number of fulfilled interceptor "
        "requests across all affected targets, and then minimizes the total "
        "assignment cost. This replaces the fairness-oriented MinMax objective with a "
        "joint assignment objective defined over all affected targets."
    ),
    15: "It compares the global assignment method and MinMax assignment using the same candidate sensors and cost matrices.",
    23: (
        "In the DES framework of [1], conflict resolution is handled using a min-max "
        "objective when multiple targets simultaneously request auxiliary sensors. "
        "This formulation prioritizes fairness by minimizing the worst-case team cost "
        "across targets. However, the approach mainly treats conflict as an event "
        "handled within one assignment procedure and does not explicitly describe "
        "the more general DES condition in "
        "which a new request competes with interceptors already committed to another "
        "target."
    ),
    24: (
        "This report builds upon that framework and focuses specifically on "
        "interceptor assignment conflict in the DES. It introduces a global "
        "assignment formulation that groups affected targets into one joint "
        "reassignment problem whenever they compete for the same candidate sensors. "
        "Unlike the original min-max method, which balances the worst-case cost, the "
        "proposed approach minimizes total assignment cost while ensuring feasibility "
        "constraints, providing an alternative objective for system-level resource "
        "allocation."
    ),
    31: (
        "The system assumptions used in the remainder of the report are as follows: "
        "the workspace is planar; sensors are homogeneous; assignment is "
        "event-triggered when a target enters the interceptor assignment process; and "
        "active trackers are excluded from candidate bidding during the current "
        "event. Each interceptor assignment event follows three steps: broadcast, "
        "bidding, and selection, corresponding to the states PENDING_BROADCAST, "
        "PENDING_BIDDING, and PENDING_SELECTION. Since different targets may enter "
        "this process at different times, a new request may compete with "
        "interceptors already committed to another target. If the requests share one "
        "or more candidate sensors, the system treats this as one interceptor "
        "assignment conflict and resolves it through a joint global assignment over "
        "the affected targets."
    ),
    53: "Assignment Workflow and Conflict Management",
    54: (
        "The interceptor assignment procedure is triggered when a tracker predicts "
        "that a target may be lost. The target then enters the interceptor "
        "assignment process and passes through the states PENDING_BROADCAST, "
        "PENDING_BIDDING, and PENDING_SELECTION while requesting new interceptors."
    ),
    55: (
        "In the DES, interceptor assignment follows three event steps: broadcast, "
        "bidding, and selection. Different targets may enter this process at "
        "different times. Therefore, a conflict occurs whenever a new interceptor "
        "request competes for one or more sensors that are already committed to "
        "another target. In V45, this conflict-handling logic is only enforced "
        "within the current assignment procedure. In V46, the same conflict "
        "management is also applied when a later request competes for interceptors "
        "that have already been committed."
    ),
    59: "Figure1: Interceptor Assignment Workflow and Conflict Management",
    60: (
        "When such a conflict is detected, the affected targets are grouped into one "
        "joint reassignment event. The assignment is then solved once across all "
        "affected targets, and the resulting interceptor assignments are broadcast to "
        "the WSN."
    ),
    62: "Global Assignment for Interceptor Selection",
    63: (
        "The joint assignment problem introduced in Section 4.1 involves assigning "
        "candidate sensors to interceptor slots of multiple targets under capacity "
        "constraints. In this report, the global assignment method enforces that each "
        "sensor is used at most once while assigning sensors to targets in a way that "
        "minimizes the total assignment cost defined in Section 3.2."
    ),
    80: "Objective Trade-off: MinMax v.s. Global Assignment",
    81: (
        "The MinMax and global assignment approaches differ fundamentally in their "
        "optimization objectives. The MinMax method minimizes the worst-case target "
        "cost, leading to a fairness-oriented assignment that prevents any target "
        "from receiving a significantly inferior interceptor configuration. This "
        "objective is particularly beneficial when balanced tracking performance "
        "across all targets is critical."
    ),
    82: (
        "In contrast, the global assignment formulation minimizes the total "
        "assignment cost across all targets under capacity constraints. This results "
        "in a globally optimal allocation in terms of overall system efficiency, but "
        "it does not explicitly enforce fairness among targets. Consequently, the two "
        "methods may produce different assignments under the same cost matrix: "
        "MinMax may sacrifice global efficiency to improve the worst-case target, "
        "while the global assignment method may accept uneven target costs if doing "
        "so reduces the total system cost."
    ),
    83: (
        "The two objectives reflect different system priorities. MinMax remains a "
        "meaningful fairness-oriented baseline because it explicitly protects the "
        "worst-case target. However, in this work, the global assignment method is "
        "adopted as the primary assignment method because the goal is to resolve "
        "interceptor assignment conflicts through a joint assignment that minimizes "
        "total system cost while enforcing non-overlapping sensor use."
    ),
    87: (
        "The interceptor assignment process is implemented as an event-driven "
        "coordination procedure within the discrete-event system (DES) framework. In "
        "the nominal case, the coordinator is selected as the active tracker of the "
        "calling target, since it maintains the most accurate and up-to-date target "
        "state estimate. When a conflict joins multiple affected targets, the "
        "coordination responsibility is transferred to one of the active trackers "
        "within the affected target group. This assumption is reasonable because such "
        "conflicts typically arise when targets are spatially close, implying that "
        "the involved sensors remain within communication range. If a target no "
        "longer has an active tracker, the coordination role is inherited by the "
        "tracker of a conflicting target. At each interceptor assignment event, a "
        "temporary coordinator is dynamically established to collect bid information "
        "from candidate sensors and compute the assignment."
    ),
    88: (
        "Each interceptor assignment event follows three steps: (1) the coordinator "
        "broadcasts an assignment request, (2) candidate sensors compute and send "
        "their local bid values, and (3) the coordinator computes the global "
        "assignment and broadcasts the result. This results in a communication cost "
        "of O(M), where M is the number of candidate sensors."
    ),
    89: (
        "When a new request competes for interceptors already committed to another "
        "target, one additional joint reassignment round is required. After the "
        "conflict is identified, the affected targets are grouped together, the "
        "interception points of previously assigned targets are updated based on the "
        "elapsed time since their original assignment, and a joint assignment request "
        "is broadcast. Candidate sensors then recompute bids for all affected targets "
        "and send updated bid values to the coordinator. The coordinator "
        "reconstructs the cost matrix, solves the joint global assignment, and "
        "broadcasts the final non-overlapping allocation. In the current MATLAB "
        "simulation, these steps are executed immediately after the conflict is "
        "detected. Under the DES interpretation, this rebidding and reselection "
        "sequence is part of normal event handling and does not have to be completed "
        "within a single update cycle as long as the overall system remains "
        "operational."
    ),
    91: "4.4.2 Computational Complexity of Global Assignment and Reassignment",
    92: (
        "The global assignment method then selects up to K interceptor sensors per "
        "target while ensuring that each candidate sensor is assigned at most once. "
        "Therefore, the number of assigned sensors is at most  The current "
        "implementation has the worst-case runtime:"
    ),
    98: (
        "While the complexity analysis in Section 4.4.2 shows that the global "
        "assignment method remains bounded and small for the current system size, "
        "asymptotic tractability alone does not determine whether the method is "
        "deployable on resource-constrained hardware. To connect the algorithmic "
        "result to a practical embedded setting, this section considers Crazyflie "
        "2.0, a small open-source quadrotor platform with a 168 MHz STM32F405 main "
        "MCU and a separate nRF51822 radio/power MCU, as a representative lower-end "
        "reference for deployment feasibility."
    ),
    99: (
        "Using the workstation measurement as an optimistic computation-only "
        "baseline, the global assignment computation time of 0.001254 s on a 4.5 "
        "GHz CPU corresponds to about 5.64 x 10^6 processor cycles. Under ideal "
        "frequency-only scaling, the same cycle count would require about 0.0336 s "
        "on the 168 MHz STM32F405, or 33.6% of a 0.1 s simulation time step. This "
        "estimate should be interpreted only as a lower-bound computation estimate, "
        "since embedded execution differs substantially from workstation MATLAB in "
        "architecture, memory hierarchy, compiler behavior, floating-point "
        "efficiency, and concurrent control workload."
    ),
    101: (
        "More importantly, the sensor-to-sensor response budget must include both "
        "computation and communication. In a normal assignment event, the coordinator "
        "broadcasts the request, collects bids, runs the solver, and broadcasts the "
        "result. In a conflict-management event, the system may need a second round "
        "of bid collection after updating the interception point, even though it "
        "still performs only one final joint global assignment computation. In a "
        "deployment-oriented DES interpretation, this reselection process need not be "
        "completed within a single update cycle, but its communication overhead still "
        "affects the overall event response time. Therefore, the extra cost of "
        "reassignment is mainly additional communication. Since even small wireless "
        "exchanges can take milliseconds, communication may consume a noticeable part "
        "of the overall response time. Hence, although the bounded problem size makes "
        "the global assignment method computationally plausible, real embedded "
        "feasibility must be confirmed with end-to-end timing on the target platform."
    ),
    105: (
        "The experiments are conducted using the simulation framework developed in "
        "[1]. The same discrete-event-system (DES) architecture, sensor models, and "
        "target motion configurations are adopted to ensure a fair comparison "
        "between the original MinMax-based assignment (V45) and the proposed global "
        "assignment-based method (V46). The only difference between the two versions "
        "lies in the interceptor assignment strategy."
    ),
    107: (
        "The same EKF-based state estimation and bidding cost formulation are used in "
        "both methods. This ensures that any differences in assignment results arise "
        "solely from the assignment strategy (MinMax vs. global assignment) and the "
        "joint reassignment mechanism for resolving interceptor assignment conflicts, "
        "rather than differences in modeling assumptions."
    ),
    111: (
        "Figure 5 shows a full simulation from V45, using the original min-max "
        "conflict resolution strategy to resolve the conflict. In V45, the "
        "conflict-handling logic is only enforced within the current assignment "
        "procedure, so a later request may still select interceptors that have "
        "already been committed to another target."
    ),
    117: (
        "This is an important observation because the system operates as a "
        "discrete-event system. Although the two requests were not handled within "
        "the same assignment procedure, the later selection by Target 2 still "
        "created a conflict with the existing interceptor assignment of Target 1. "
        "This is the normal interceptor assignment conflict condition in the DES. "
        "As a result, Target 1 loses one of its interceptors, which potentially "
        "increases its risk of target loss. Therefore, this case should be treated "
        "as a conflict event."
    ),
    118: (
        "To address this issue, a new conflict-management mechanism is introduced in "
        "example_V46_Yeqi.m (V46). In V46, when a target attempts to select an "
        "interceptor that is already assigned to another target, the system treats "
        "the affected requests as one interceptor assignment conflict. Compared with "
        "V45, the same conflict handling is now also applied when a later request "
        "competes for interceptors that have already been committed to another "
        "target. Instead of allowing the new target to simply take the sensor away, "
        "the affected targets are grouped together, and a new round of selection is "
        "performed across all of them. The reassignment does not strictly protect "
        "the original assignment; instead, it evaluates whether reassigning the "
        "sensor leads to a better global solution. In this situation, the global "
        "assignment formulation arises naturally: the conflicting targets and their "
        "candidate interceptors form a shared assignment problem. By solving this "
        "problem in a global scope, the system can determine the minimum-cost "
        "combination of interception assignments for both targets, rather than "
        "optimizing each target independently. If a sensor is reassigned, the "
        "original target is simultaneously reassigned alternative interceptors "
        "within the same reassignment step. This allows the final interceptor "
        "allocation to be globally optimal across the affected group of targets."
    ),
    123: (
        "Figure 7 shows the result after applying the V46 fix. At t = 39.5 s, "
        "Target 2 no longer takes Sensor 14 away from Target 1. Instead, the updated "
        "joint global selection assigns Sensor 13 and Sensor 20 to Target 2, while "
        "Target 1 retains its assigned interceptors. This confirms that the revised "
        "conflict-management logic prevents an active interception assignment from "
        "being overwritten by a later target selection."
    ),
    125: "MinMax V.S. Global Assignment",
    126: (
        "This section compares the assignment results produced by MinMax and the "
        "global assignment method under the same conflict scenario. The goal is not "
        "to evaluate which method is better, but to illustrate how different "
        "optimization objectives lead to different assignment outcomes."
    ),
    131: "Table 4: Interceptor Assignment Comparison Between MinMax and Global Assignment",
    130: (
        "Figure 8 shows the full simulation result from V46 after introducing the "
        "updated conflict-management mechanism. At t = 39.5 s, Target 1 and Target 2 "
        "trigger an assignment conflict, causing the system to perform a joint "
        "reassignment process to find a better global interceptor allocation."
    ),
    132: (
        "Table 4 summarizes the interceptor assignment results produced by MinMax "
        "and the global assignment method for the conflict event at t = 39.5. "
        "Overall, the global assignment method reduces the total assignment cost "
        "from 1.181 to 1.084. The difference arises from the distinct optimization "
        "objectives. MinMax prioritizes balancing the worst-case target cost, while "
        "the global assignment method minimizes the total assignment cost across all "
        "targets. As a result, the two methods select different sensor combinations "
        "under the same scenario."
    ),
    135: (
        "This report reformulates interceptor assignment in cooperative multi-target "
        "tracking as a global assignment problem with joint conflict management. "
        "Compared with the MinMax method, the proposed approach provides one "
        "consistent way to resolve interceptor assignment conflicts in the DES while "
        "improving global assignment efficiency. The current results suggest that "
        "the method is computationally practical for the bounded WSN scale studied "
        "here, although embedded deployment feasibility still requires "
        "communication-aware validation on target hardware."
    ),
}

TABLE_REPLACEMENTS = {
    (1, 3, 0): "Global Assignment",
    (1, 4, 0): "Global Assignment",
}


def copy_run_format(src_run, dst_run) -> None:
    if src_run is None:
        return
    dst_run.style = src_run.style
    dst_run.bold = src_run.bold
    dst_run.italic = src_run.italic
    dst_run.underline = src_run.underline
    dst_run.font.name = src_run.font.name
    dst_run.font.size = src_run.font.size
    if src_run.font.color.rgb is not None:
        dst_run.font.color.rgb = src_run.font.color.rgb


def set_paragraph_text(paragraph, text: str) -> None:
    source_run = next((run for run in paragraph.runs if run.text), None)
    p = paragraph._element
    for child in list(p):
        if child.tag.endswith("}pPr"):
            continue
        p.remove(child)
    new_run = paragraph.add_run(text)
    copy_run_format(source_run, new_run)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    doc = Document(str(INPUT_DOCX))

    changes = []
    for index, new_text in REPLACEMENTS.items():
        paragraph = doc.paragraphs[index]
        old_text = paragraph.text.replace("\xa0", " ")
        if old_text != new_text:
            changes.append(
                {
                    "paragraph_index": index,
                    "old_text": old_text,
                    "new_text": new_text,
                }
            )
        set_paragraph_text(paragraph, new_text)

    for (table_index, row_index, col_index), new_text in TABLE_REPLACEMENTS.items():
        cell = doc.tables[table_index].rows[row_index].cells[col_index]
        old_text = cell.text.replace("\xa0", " ")
        if old_text != new_text:
            changes.append(
                {
                    "table_index": table_index,
                    "row_index": row_index,
                    "col_index": col_index,
                    "old_text": old_text,
                    "new_text": new_text,
                }
            )
        cell.text = new_text

    doc.save(str(OUTPUT_DOCX))
    OUTPUT_JSON.write_text(json.dumps(changes, indent=2, ensure_ascii=False), encoding="utf-8")

    print(OUTPUT_DOCX)
    print(OUTPUT_JSON)
    print(f"changed_paragraphs={len(changes)}")


if __name__ == "__main__":
    main()
