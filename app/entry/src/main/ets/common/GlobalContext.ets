import { Context } from '@kit.AbilityKit'

class GlobalContext {
  private static instance: GlobalContext = new GlobalContext()
  private context: Context | null = null

  private constructor() {}

  static getInstance(): GlobalContext {
    return GlobalContext.instance
  }

  setContext(context: Context): void {
    this.context = context
  }

  getContext(): Context | null {
    return this.context
  }
}

export default GlobalContext