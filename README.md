# AstroForge 🛰️
**Autonomous Space Debris Capture and Recycling System**

*Developed by **Team Nova Foundary** for the AESS Sustainability Hackathon 2026 (Track 4: Orbital Lifecycle).*

---

## 🌍 Overview
AstroForge is a highly autonomous **795 kg spacecraft** designed for In-Situ Resource Utilization (ISRU). It tackles the growing threat of Kessler Syndrome in Low Earth Orbit (LEO) and Sun-Synchronous Orbits (SSO) by actively capturing metallic space debris and recycling it into usable plasma propellant.

## ⚙️ System Architecture
Our design integrates a hybrid continuous/discrete simulation environment to validate:
- **Capture Mechanism:** 6-blade Iris, 45°/s servo-actuated for dynamic debris interception.
- **Electromagnetic Brake:** 715-turn Copper coil (20A peak, 560W) utilizing Eddy currents to dissipate kinetic energy without mechanical impact.
- **Power Management:** 1kW Solar Array + 5kWh Li-ion Battery + 20kJ Supercapacitor for high-pulse discharge.
- **ADCS Control:** PID-tuned stabilization ensuring ±0.5° accuracy during capture sequences.

## 📊 Simulation Performance (Validated)
Our `ode3` fixed-step MATLAB/Simulink models demonstrate:
- **Kinetic Neutralization:** Reduced debris velocity from **50 m/s to 0 m/s in exactly 6 seconds**.
- **Energy Efficiency:** Achieved **76% braking efficiency** (consuming 7 kJ per capture).
- **Thermal Safety:** Coil temperature stabilized at **65°C** (critical limit: 150°C).

## 🚀 How to Run the Simulation
To reproduce our results, follow these steps:
1. Clone this repository to your local machine.
2. Open MATLAB (R2021b or later recommended).
3. Run the automated builder script: 
   ```matlab
   run('AstroForge_Builder_V5_2.m')
