/**
 * @description Scheduler for DMS replenishment. Generates draft replenishment
 *              indents across all distributors on a recurring schedule.
 *
 *              Example (daily 6am):
 *              System.schedule('DMS Replenishment', '0 0 6 * * ?', new DMS_Replenishment_Scheduler());
 * @author  SFA Development Team
 * @date    2024
 */
public class DMS_Replenishment_Scheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        DMS_Replenishment_Service.generateAll();
    }
}