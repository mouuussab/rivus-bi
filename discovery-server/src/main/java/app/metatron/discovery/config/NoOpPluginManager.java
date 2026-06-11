package app.metatron.discovery.config;

import org.pf4j.DefaultPluginManager;
import org.pf4j.PluginDescriptor;
import org.pf4j.PluginWrapper;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

public class NoOpPluginManager extends DefaultPluginManager {
  
  public NoOpPluginManager() {
    super(Paths.get(""));
  }
  
  @Override
  public void loadPlugins() {
    // No-op
  }
  
  @Override
  public List<PluginWrapper> getResolvedPlugins() {
    return new ArrayList<>();
  }
  
  @Override
  public List<PluginWrapper> getStartedPlugins() {
    return new ArrayList<>();
  }
}
