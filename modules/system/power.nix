# Battery policy. upower decides what happens as the battery runs down; it comes
# in via Plasma's defaults, but the defaults are wrong for this machine.
#
# The stock policy is CriticalPowerAction=HybridSleep at PercentageAction=2.
# HybridSleep writes a full memory image to swap (~5.5 GB, ~25 s of sustained
# NVMe writes) and *then* parks in s2idle, so it pays the most expensive part of
# hibernation and still keeps draining afterwards. Starting that at 2% on a worn
# cell is what leaves the laptop dead mid-transition: the panel has already been
# blanked, the write never finishes, and the EC latches until you force it off.
#
# This battery is at ~63% of design capacity (2673/4220 mAh, 464 cycles), and a
# degraded cell's last few percent collapse much faster than the gauge reports.
# So: act at 15% instead of 2%, and use Hibernate, which performs the same write
# but actually powers off at the end instead of idling on what's left.
#
# If the write itself ever becomes too risky as the battery ages further, switch
# criticalPowerAction to "PowerOff" — no image, no resume, session lost, but it
# cannot fail partway. ("Suspend" and "Ignore" are the only values NixOS gates
# behind allowRiskyCriticalPowerAction; Hibernate and PowerOff need no flag.)
{
  flake.nixosModules.power =
    { ... }:
    {
      services.upower = {
        enable = true;

        criticalPowerAction = "Hibernate";

        # percentageAction is the only one of the three that does anything on
        # this machine. upower does not itself notify — it publishes a
        # WarningLevel over D-Bus for a desktop shell to render, and nothing here
        # subscribes: powerdevil only runs under Plasma, and waybar's battery
        # module reads sysfs directly. But upower requires
        # low > critical > action and silently falls back to its stock defaults
        # (HybridSleep at 2%) if that ordering is violated, so these two exist
        # only to sit above the 15% threshold.
        usePercentageForPolicy = true;
        percentageLow = 30;
        percentageCritical = 20;
        percentageAction = 15;
      };
    };
}
