// node_modules
import React from "react";
import { Link } from "react-router-dom";
import SVG from "react-inlinesvg";

// local imports
import "./Layout.scss";
import Logo from '../../assets/logo.svg';
import IconDashboard from '../../assets/icon-dashboard.svg';
import IconAlerts from '../../assets/icon-alerts.svg';
import IconReports from '../../assets/icon-reports.svg';
import IconModels from '../../assets/icon-models.svg';
import IconMaintenance from '../../assets/icon-maintenance.svg';
import IconSettings from '../../assets/icon-settings.svg';
import Toast from "../Toast";

export const Layout = ({ children, selected, showToast, setShowToast }) => {
  return (
    <div className="Layout">
      <header>
        <nav>
          <ul>
            <li className="logo">
              <Link to="/dashboard"><SVG src={Logo} /></Link>
            </li>
            <li className={selected === 'dashboard' ? 'selected' : ''}>
              <Link to="/dashboard"><SVG src={IconDashboard} />Dashboard</Link>
            </li>
            <li className={selected === 'alerts' ? 'selected' : ''}>
              <Link to="/alerts"><SVG src={IconAlerts} />Alerts</Link>
            </li>
            <li className={selected === 'reports' ? 'selected' : ''}>
              <Link to="/dashboard"><SVG src={IconReports} />Reports</Link>
            </li>
            <li>
              <Link to="/dashboard"><SVG src={IconModels} />Models</Link>
            </li>
            <li>
              <Link to="/dashboard"><SVG src={IconMaintenance} />Maintenance</Link>
            </li>
            <li>
              <Link to="/dashboard"><SVG src={IconSettings} />Settings</Link>
            </li>
          </ul>
        </nav>
      </header>
      <main>{children}</main>
      {showToast && <Toast onClose={() => {setShowToast(false)}} />}
    </div>
  );
}
