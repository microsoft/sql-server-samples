//----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
//----------------------------------------------------------------------------------
// The example companies, organizations, products, domain names,
// e-mail addresses, logos, people, places, and events depicted
// herein are fictitious.  No association with any real company,
// organization, product, domain name, email address, logo, person,
// places, or events is intended or should be inferred.

using Gauge = CircularGauge.CircularGaugeControl;
using MediaColor = System.Windows.Media.Color;
using System;

namespace DemoWorkload
{
    public class UIControls
    {
        Gauge _speedDial = new Gauge();

        public Gauge speedDial { get { return _speedDial; }}
        public UIControls()
        {
            SpeedDialInit();
        }
        private void SpeedDialInit()
        {
            // Initialize CircularGauge Control
            _speedDial.Radius = 120;
            _speedDial.DialBorderThickness = 0;
            _speedDial.ScaleRadius = 110;
            _speedDial.ScaleStartAngle = 120;
            _speedDial.ResetPointerOnStartUp = true;
            _speedDial.ScaleSweepAngle = 300;
            _speedDial.PointerLength = 85;
            _speedDial.PointerCapRadius = 0;
            _speedDial.MinValue = 0;
            _speedDial.MaxValue = 60;
            _speedDial.DialText = "0";
            _speedDial.MajorDivisionsCount = 10;
            _speedDial.MinorDivisionsCount = 5;
            _speedDial.RangeIndicatorThickness = 0;
            _speedDial.RangeIndicatorRadius = 0;
            _speedDial.ScaleLabelRadius = 90;
            _speedDial.ScaleLabelFontSize = 12;
            _speedDial.ScaleLabelForeground = MediaColor.FromRgb(0, 0, 0); // Black
            _speedDial.MajorTickColor = MediaColor.FromRgb(169, 169, 169); // DarkGray
            _speedDial.MinorTickColor = MediaColor.FromRgb(169, 169, 169); // DarkGray
            _speedDial.ImageOffset = -50;
            _speedDial.GaugeBackgroundColor = MediaColor.FromRgb(255, 255, 255); // White
            _speedDial.PointerThickness = 5;
            _speedDial.DialTextOffset = 100;
            _speedDial.DialTextColor = MediaColor.FromRgb(0, 0, 0); // Red
            _speedDial.DialBorderThickness = 0;
        }
    }
}
