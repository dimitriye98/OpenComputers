package li.cil.oc.server.component

import li.cil.oc.api.driver.EnvironmentHost
import li.cil.oc.common.tileentity.traits.BundledRedstoneAware
import li.cil.oc.common.tileentity.traits.RedstoneAware
import li.cil.oc.server.component

object Redstone {

  class Vanilla(val redstone: EnvironmentHost with RedstoneAware)
    extends component.RedstoneVanilla

  class Bundled(val redstone: EnvironmentHost with BundledRedstoneAware)
    extends component.RedstoneVanilla with component.RedstoneBundled

  class Wireless(val redstone: EnvironmentHost)
    extends component.RedstoneWireless

  class VanillaWireless(val redstone: EnvironmentHost with RedstoneAware)
    extends component.RedstoneVanilla with component.RedstoneWireless

  class BundledWireless(val redstone: EnvironmentHost with BundledRedstoneAware)
    extends component.RedstoneVanilla with component.RedstoneBundled with component.RedstoneWireless

}
