#ifndef ROBOT_HARDWARE_COMPONENT_HPP
#define ROBOT_HARDWARE_COMPONENT_HPP

#include <memory>
#include <string>
#include <vector>

#include "hardware_interface/handle.hpp"
#include "hardware_interface/hardware_info.hpp"
#include "hardware_interface/system_interface.hpp"
#include "hardware_interface/types/hardware_interface_return_values.hpp"
#include "rclcpp/clock.hpp"
#include "rclcpp/duration.hpp"
#include "rclcpp/macros.hpp"
#include "rclcpp/time.hpp"
#include "rclcpp_lifecycle/node_interfaces/lifecycle_node_interface.hpp"
#include "rclcpp_lifecycle/state.hpp"

#include "control/microcontroller_comms.hpp"
#include "control/can_comms.hpp"

// TODO: Ctrl+F and replace the word robot (turn off case sensitivity) with your robot name

namespace robot_hardware_component
{
    class RobotHardwareComponent : public hardware_interface::SystemInterface
    {
        public:
            RCLCPP_SHARED_PTR_DEFINITIONS(RobotHardwareComponent)

            hardware_interface::CallbackReturn on_init(
                const hardware_interface::HardwareComponentInterfaceParams & params) override;
            
            hardware_interface::CallbackReturn on_configure(
                const rclcpp_lifecycle::State & previous_state) override;
            
            hardware_interface::CallbackReturn on_cleanup(
                const rclcpp_lifecycle::State & previous_state) override;
            
            hardware_interface::CallbackReturn on_activate(
                const rclcpp_lifecycle::State & previous_state) override;
            
            hardware_interface::CallbackReturn on_deactivate(
                const rclcpp_lifecycle::State & previous_state) override;

            std::vector<hardware_interface::StateInterface> export_state_interfaces() override;
            std::vector<hardware_interface::CommandInterface> export_command_interfaces() override;
            
            hardware_interface::return_type read(
                const rclcpp::Time & time, const rclcpp::Duration & period) override;
            
            hardware_interface::return_type write(
                const rclcpp::Time & time, const rclcpp::Duration & period) override;
            
        private:
            MicrocontrollerComms microcontroller_comms_;
            CanComms can_comms_;

            // Hardware Parameters (Pulled from URDF)
            std::string serial_port_;
            int baud_rate_;
            std::string can_interface_;

            // Motor pulses/meter here
            

            // Any maximum speeds here


            // Tracking variables here
            
            // Extra variables or whatever you want

    };
}   // namespace robot_hardware_component

#endif // ROBOT_HARDWARE_COMPONENT_HPP